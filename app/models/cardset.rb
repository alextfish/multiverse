# == Schema Information
# Schema version: 20101215230231
#
# Table name: cardsets
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  user_id      :integer
#  description  :text
#  created_at   :datetime
#  updated_at   :datetime
#  last_edit_by :integer
#


require 'csv'

class Cardset < ActiveRecord::Base
  attr_accessible :name, :description
  belongs_to :user, touch: true
  has_many :cards, :dependent => :destroy
  has_many :admins, :class_name => "User"
  has_many :details_pages, :dependent => :destroy
  has_many :mechanics, :dependent => :destroy 
  has_one :configuration, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :logs
  has_one :news_list, :dependent => :destroy
  has_one :last_edit_log, :class_name => "Log", :dependent => :destroy
  has_many :decklists, :dependent => :destroy
  
  default_scope { includes(:configuration).order("cardsets.updated_at DESC") }

  validates_length_of :name, :within => 2..40
  validate do |cardset|
    if cardset.configuration.errors
      cardset.configuration.errors.full_messages.each do |msg|
        cardset.errors.add_to_base(msg)
      end
    end
  end

  def get_stats
    out = {}
    out[:by_category] = Hash.new(0)
    out[:by_rarity] = Hash.new(0)
    cards.nonsecondary.eager_load(:link,:parent).each do |card|
      out[:by_category][card.category || "unspecified"] += 1
      out[:by_rarity][card.rarity || "unspecified"] += 1
    end
    out
  end
  
  def all_comments
    # Includes comments directly on the cardset and those on
    # cards in the cardset
    #card_comments = Comment.includes(:card).where("cards.cardset_id = ?", self.id).references(:card)
    #cardset_comments = Comment.where("cardset_id = ?", self.id)
    #(cardset_comments + card_comments)
    self.comments.includes(:user, :card)
  end
  
  def cardset_level_comments
    # Includes only comments without a card
    cardset_comments = Comment.includes(:user, :cardset).where("cardset_id = ? AND card_id IS NULL", self.id)
  end
  
  def log(in_hash)
    # Create the Log
    new_log = self.logs.create :kind=>Log.kind(in_hash[:kind]), 
                    :datestamp=>Time.now, 
                    :user=>in_hash[:user], 
                    :object_id=>in_hash[:object_id],
                    :text=>in_hash[:text]

    logs_to_not_show = Log.kinds_to_not_show(:cardset_recent)
    if logs_to_not_show.include?(new_log.kind)
      Rails.logger.info("Not logging to speedy-RC because this log type shouldn't be shown")
    else
      # Create the LastEditLog
      #desired_attributes = new_log.attributes.except("object_id").except("id")
      #if last_edit_log
      #  last_edit_log.delete
      #end
      #last_edit_log = LastEditLog.new desired_attributes
      #last_edit_log.update_attributes desired_attributes
      last_edit_log_id = new_log.id
      
      # Create the NewsList log
      news_list.add_log(new_log)
	  
      # Update the GlobalState
      globalState = GlobalState.instance
      globalState.lastedit = new_log.datestamp
      globalState.save!
    end
    return new_log
  end
  
  def recent_action
    if last_edit_log_id
      out = Log.find(last_edit_log_id)
    else
      out = self.logs.first
    end
    # out = self.last_edit_log || self.logs.first
    logs_to_not_show = Log.kinds_to_not_show(:cardset_recent)
    if out.nil? || logs_to_not_show.include?(out.kind) 
      out = self.logs.reject{ |l| logs_to_not_show.include?(l.kind) }.first
    end
    out
  end
  
  def clear_cache
    # Clear the cardset cache /for anything that uses the iterator/
    # As of 11th Jan this is only the visual spoiler
    Rails.cache.write("cardset-#{self.id}-memcache-iterator", self.memcache_iterator + 1)
  end
  def memcache_iterator
    # fetch the cardset's memcache key
    # If there isn't one yet, assign it to 0
    Rails.cache.fetch("cardset-#{self.id}-memcache-iterator") { 0 }.to_i
  end
  
  def datestamps_close(d1,d2)
    (d1-d2).abs < 20.seconds
  end
  
  def public_cards
    if configuration.card_show_active
      self.cards.nonsecondary.active
    else
      self.cards.nonsecondary
    end
  end
  def listable_cards # For cardlists that should include nonactive cards
    Card.includes(:comments, :user).nonsecondary.where("cardset_id = ?", self.id)
  end 
  def draftable_cards # Include secondary cards as their own records for JSON purposes
    if configuration.card_show_active
      self.cards.where(:active => true )
    else
      self.cards
    end
  end
  
  ########################## Permissions #########################  

  @@permitted_users_are = {
    # DB entry => Text
    "anyone" => "All users are",
    "signedin" => "Only signed-in users are",
    "admins" => "Only cardset administrators are",
    "selected" => "Only users specified by the cardset administrators are",
    "justme" => "Only the cardset owner is",
  }

  def permission_message(action)
    case action
      when :comment
        verb = "comment on"
        perm = configuration.commentability
      when :view
        verb = "view"
        perm = configuration.visibility
      when :edit
        verb = "edit"
        perm = configuration.editability
      when :delete
        verb = "delete cards in"
        perm = configuration.adminability
      when :admin
        verb = "take admin actions on"
        perm = configuration.adminability
      else
        raise "Bad input to permission_message #{action}"
    end
    @@permitted_users_are[perm] + " permitted to #{verb} this cardset."
  end

  def permission_to?(action)
    case action
      when :comment
        permitted_people = configuration.commentability
      when :view
        permitted_people = configuration.visibility
      when :edit
        permitted_people = configuration.editability
      when [:admin, :delete]
        permitted_people = configuration.adminability
      else
        raise "Bad input to permission_to?(#{action})"
    end
    case permitted_people.to_s
      when "anyone"
        out = true
      when "signedin"
        out = signed_in?
      when "admins"
        out = signed_in_as_admin?(self)
      when "justme"
        out = signed_in_as_owner?(self)
      when "selected"
        return configuration.permitted_users(action).include?(current_user.name)
      else
        raise "Unexpected value of configuration property in action #{action}: #{permitted_people}"
    end
  end
  
  def public_access
   if ['justme', 'admins', 'selected'].include? configuration.visibility
     "Private"
   elsif !['justme', 'admins', 'selected'].include? configuration.editability
     "Editable"
   else
     "Viewable"
   end
  end
  
  
  def is_card_name?(some_name)
    !!self.cards.find_by_name(some_name)
  end
  
  ################### Manual updates ###################

  def Cardset.add_news_lists
    kinds_to_not_show = Log.kinds_to_not_show(:cardset_recent)
    Cardset.all.each do |cs|
      if !cs.news_list
        cs.news_list = NewsList.new
        recent_logs = cs.logs.reject{ |l| kinds_to_not_show.include?(l.kind) }
        recent_logs.take(NewsList.MAX_LENGTH + 1).reverse.each {|l| cs.news_list.add_log(l)}
      end
    end
  end
  
  ########################## Skeletons #########################  
  def skeleton
    self.details_pages.select{|dp| dp.title == DetailsPage.SKELETON_TITLE }[0]
  end
  def front_page
    self.details_pages.select{|dp| dp.title == DetailsPage.FRONT_PAGE_TITLE }[0]
  end
  def details_pages_except_front_page
    self.details_pages.reject{|dp| dp.title == DetailsPage.FRONT_PAGE_TITLE }
  end
  
  def Cardset.rarity_initials 
    "CURMBT"
  end
  def Cardset.skeleton_line_regexp_MD
    /^\(\(\((?:[-]?)([#{rarity_initials}])([A-Z])([0-9][0-9])/
  end
  def Cardset.skeleton_line_regexp_HTML
    /(?:>[(]?)([#{rarity_initials}])([A-Z])([0-9][0-9])/
  end
  
  def build_name_and_code_lookup_table
    cardset_cardnames_and_codes = []
    cardset_cards_from_name_or_code = {}
    self.cards.eager_load(:link).each do |card|
      if card.name
        cardset_cardnames_and_codes << card.name
        cardset_cards_from_name_or_code[card.name] = card
        if card.split? && card.primary? && !card.link.name.blank?
          # Allow links to "Fire // Ice" as well as "Ice"
          cardset_cardnames_and_codes << card.printable_name
          cardset_cards_from_name_or_code[card.printable_name] = card
        end
      end
      if card.code
        cardset_cardnames_and_codes << card.code
        cardset_cards_from_name_or_code[card.code] = card
      end
    end
    return [cardset_cardnames_and_codes, cardset_cards_from_name_or_code]
  end
  
  def get_skeleton_row(code)
    if !skeleton
      return nil
    end
    skeleton.body.lines.find {|line| line.include? code}
  end
  def get_skeleton_header_rows
    if !skeleton
      return ""
    end
    line1 = skeleton.body.lines.find {|line| line =~ /^[|](.*[|])+/ } || ""    # first line with bars
    line2 = skeleton.body.lines.find {|line| line =~ /^[|]([:-]*[|])+/ } || "" # first line with bars separated only by colons and dashes
    line1 + line2
  end
  def get_skeleton_cards
    code_regexp = /\(\(\(-([^)]*)\)\)\)/
    skeleton_card_codes = skeleton.body.lines.map { |line| 
      matches = line.match(code_regexp)
      matches && matches[1]
    }
    cardnames_and_codes, cards_from_name_or_code = build_name_and_code_lookup_table
    skeleton_cards = skeleton_card_codes.select {|code|
      cardnames_and_codes.include? code
    }.map {|code| 
      cards_from_name_or_code[code]
    }
  end
  
  def generate_skeleton(params)
    ok_so_far = true
    # Read existing skeleton content: 
    # assemble array all_existing_codes and hash line_numbers_for_code
    @skeleton = self.skeleton
    
    code_lines = []
    all_existing_codes = []
    line_numbers_for_code = {}
    insertions = []
    if !@skeleton.nil?
      all_lines = @skeleton.body.lines
      all_lines.each_with_index do |line, index|
        if line =~ Cardset.skeleton_line_regexp_MD
          # code_lines_and_numbers << [line, index]
          data = line.match(Cardset.skeleton_line_regexp_MD) 
          code = data[1] + data[2] + data[3]
          all_existing_codes << code
          line_numbers_for_code[code] = index
        end
      end
    end
    # Generate virtual params for blue, black, red and green, equal to white
    %w{blue black red green}.each do |colour|
      Cardset.rarity_initials.split("").each do |rarity_letter|
        params["skeletonform_#{colour}_rarity#{rarity_letter}"] = params["skeletonform_white_rarity#{rarity_letter}"]
      end
    end

    # For each frame-rarity combo (which all start with skeletonform_):
    rarity_frame_regexp = /skeletonform_([a-z]*)_rarity([A-Z])/
    %w{C U R M}.each do |rarity|
      if params[:"skeletonform_allyhybrid_rarity#{rarity}"] || 
          params[:"skeletonform_enemyhybrid_rarity#{rarity}"]
        params[:"skeletonform_hybrid_rarity#{rarity}"] = 
          (params.delete(:"skeletonform_allyhybrid_rarity#{rarity}") || 0) + 
          (params.delete(:"skeletonform_enemyhybrid_rarity#{rarity}") || 0)
      end
      if params[:"skeletonform_allygold_rarity#{rarity}"] || 
          params[:"skeletonform_enemygold_rarity#{rarity}"]
        params[:"skeletonform_gold_rarity#{rarity}"] = 
          (params.delete(:"skeletonform_allygold_rarity#{rarity}") || 0) + 
          (params.delete(:"skeletonform_enemygold_rarity#{rarity}") || 0)
      end
    end
    params.select{|param_key, param_value| param_key =~ /^skeletonform_/}.each do |param_key, param_value|
      if !param_key =~ rarity_frame_regexp
        raise "Unexpected param #{param_key}"
      end
      # read rarity_letter, frame_letter, and number_in from the form entry
      number_in = param_value.to_i
      # if number is 0: next
      if number_in == 0
        next
      end
      frame_code = param_key.match(rarity_frame_regexp)[1]
      rarity_letter = param_key.match(rarity_frame_regexp)[2]
      case frame_code
        when "white" then frame_letter = "W"
        when "blue" then frame_letter = "U"
        when "black" then frame_letter = "B"
        when "red" then frame_letter = "R"
        when "green" then frame_letter = "G"
        when "artifact" then frame_letter = "A"
        when "land" then frame_letter = "L"
        when "gold" then frame_letter = "Z"; number_in *= 5
        when "hybrid" then frame_letter = "H"; number_in *= 5
        else raise "Unexpected frame_code #{frame_code}"
      end
      Rails.logger.info "Rarity #{rarity_letter}, frame #{frame_letter}: making #{number_in}"
      # calculate "new lines" - codes that we need that don't already exist
      new_range = (1..number_in).map {|num| "#{rarity_letter}#{frame_letter}%02d" % num}
        
      
      new_codes = new_range.select{|c| !all_existing_codes.include?(c) }
      # if no new codes:
      if new_codes.empty?
        Rails.logger.info "No new codes for #{rarity_letter}#{frame_letter}"
        # do nothing
      # elsif some of the codes we're making for this rarity+frame already exist:
      elsif new_codes.length < new_range.length
        # find last line num of existing codes
        existing_codes_this_frame_and_rarity = new_range - new_codes
        last_line_num = highest_line_num existing_codes_this_frame_and_rarity, line_numbers_for_code
        # insert new lines immediately after last code. this allows them to delete CW02 and it reappears after CW18, but meh
        insertions << [new_codes, last_line_num+1]
        Rails.logger.info "Adding #{new_codes.length} new codes for #{rarity_letter}#{frame_letter}"
      else # none of the codes we're making for this rarity+frame already exist
        # Look for any code with this frame
        existing_codes_this_frame = all_existing_codes.select {|code| code[1].chr == frame_letter }
        # if any lines exist for this frame:
        if !existing_codes_this_frame.empty?
          #existing_rarities = existing_codes_this_frame.map{|code| code[1].chr}
          existing_codes_previous_rarities = case rarity_letter
            when "C" then []
            when "U" then existing_codes_this_frame.select {|code| code[0]==?C}
            when "R" then existing_codes_this_frame.select {|code| [?C,?U].include? code[0]}
            when "M" then existing_codes_this_frame # already established there are no mythics
            else
              raise "Unexpected rarity letter #{rarity_letter}"
          end
          # if any lines exist for previous rarities in this frame:
          if !existing_codes_previous_rarities.empty?
            # insert new lines immediately after last previous rarity
            last_line_num = highest_line_num existing_codes_previous_rarities, line_numbers_for_code
            Rails.logger.info "Generating new rarity section for frame #{frame_letter} rarity #{rarity_letter}, after the previous ones: line #{last_line_num}"
            insertions << [new_codes, last_line_num+1]
          else
            # insert new lines immediately before first line (since it's a subsequent rarity)
            first_line_num = lowest_line_num existing_codes_this_frame, line_numbers_for_code
            Rails.logger.info "Generating new rarity section for frame #{frame_letter} rarity #{rarity_letter}, before all previous ones: line #{first_line_num}"
            insertions << [new_codes, first_line_num]
          end
          Rails.logger.info "Adding #{new_codes.length} new codes for #{rarity_letter}#{frame_letter}"
        else # no lines exist for this frame:
          Rails.logger.info "All existing codes: #{all_existing_codes.inspect}"
          if all_existing_codes.empty?
            # Add these codes at line 0 along with all the others
            insertions << [new_codes, 0]
          else
            # Some frames exist. Find the last one before us in the frame order.
            preceding_codes = all_existing_codes.select do |code|
              Card.frame_code_letters.index(code[1].chr) < Card.frame_code_letters.index(frame_letter)
            end
            last_line_num = highest_line_num preceding_codes, line_numbers_for_code
            if last_line_num == 0
              # If there are none, insert at the first code line 
              target_line_num = lowest_line_num all_existing_codes, line_numbers_for_code
            else
              # If there are some preceding codes, insert immediately after them
              target_line_num = last_line_num+1
            end
            insertions << [new_codes, target_line_num]
          end
        end
      end
    end
    
    Rails.logger.info "Insertions: #{insertions.inspect}"
    
    # now handle the insertions - if there are any
    if insertions.empty?
      return false
    end
    
    # first, figure out how many |s there are in the first table line
    # Default table has 3 columns, 3 bars
    number_of_bars = 3
    if @skeleton.nil?
      lines_out = []
    else
      lines_out = all_lines.to_a
      first_table_line = all_lines.find{|line| line.include? "|"}
      if !first_table_line.nil?
        # The table header line has extra bars at the start
        # So if the header has 5 bars, it'll have 6 parts split by "|"
        # Normal lines want 4 bars, so we take the split count -2
        number_of_bars = first_table_line.split("|").count - 2
      end
    end
    
    # now insert lines into lines_out, from the end first so the line numbers stay valid
    frame_offsets = {}
    Card.frame_code_letters.each_with_index {|letter, index| frame_offsets[letter] = 0.05*index }
    # could deduce from rarity_initials, but fiddly
    rarity_offsets = {"C" => 0, "U" => 0.01, "R" => 0.02, "M" => 0.03, "B" => 0.04, "T" => 0.05}
    insertions.sort_by {|codes, line_num| line_num + rarity_offsets[codes[0][0].chr] + frame_offsets[codes[0][1].chr]}.reverse_each do |codes, line_num|
      # To insert lines for [a b c] at position 5, we insert c at 5, then b at 5, then a at 5
      codes.reverse.each do |code|
        new_line = "(((-#{code})))" + (" | " * number_of_bars) + "\n"
        lines_out.insert line_num, new_line
      end
    end
    
    # Now lines_out contains the new skeleton body
    # Existing lines and inserted lines all end with "\n", so we just join() them
    if @skeleton.nil?
      @skeleton = self.details_pages.build(:title => "Skeleton")
      lines_out = ["|Code | Slot | Notes |\n", "|:---:|------|---------|\n"] + lines_out
    end
    @skeleton.body = lines_out.join
    @skeleton.save!
    return true
  end

  def highest_line_num (codes_in, line_numbers_for_code)
    codes_in.reduce(0) do |current_highest_line_num, code|
      this_line_num = line_numbers_for_code[code]
      if this_line_num.nil? || this_line_num <= current_highest_line_num
        current_highest_line_num
      else
        this_line_num 
      end
    end
  end
  def lowest_line_num (codes_in, line_numbers_for_code)
    codes_in.reduce(999999) do |current_lowest_line_num, code|
      this_line_num = line_numbers_for_code[code]
      if this_line_num.nil? || this_line_num >= current_lowest_line_num
        current_lowest_line_num
      else
        this_line_num 
      end
    end
  end
  

  ########################## Boosters ##########################
  def cards_per_line
    case configuration.frame
      when "prettycard" then 5
      when "plain" then 2
      when "image" then 3
    end
  end
  
  BOOSTER_STRUCTURES = {
    "m10" => [ 
              ["rare", "mythic"], # this differs from mtg-json which says 'mythic rare' not 'mythic'
               "uncommon", "uncommon", "uncommon",
               "common", "common", "common", "common", "common", "common", "common", "common", "common", "common",
               "basic", "token",
              ],
    "old" => [ 
               "rare",
               "uncommon", "uncommon", "uncommon",
               "common", "common", "common", "common", "common", "common", "common", "common", "common", "common", "common",
               "token",
              ]
  }
  def booster_structure
    mythics   = self.public_cards.select { |c| c.rarity == "mythic"   } 
    collation = mythics.any? ? "m10" : "old"
    [collation, BOOSTER_STRUCTURES[collation]]
  end

  def make_booster(flat)
    cards_to_use = self.public_cards
    @booster = []
    
    if flat   
      tokens = cards_to_use.select{|c| c.rarity == "token"}
      cards_to_use -= tokens
      tokens_present = !tokens.empty?
      num_cards = (tokens_present ? 14 : 15)
      while @booster.length < 15
        if cards_to_use.empty?
          @booster << Card.blank("No more cards")
        else
          new_candidate = cards_to_use.sample
          @booster << new_candidate 
          cards_to_use -= [new_candidate]
        end
      end
      if tokens_present
        @booster << tokens.sample
      end
      collation = "flat"
    else
      # Use rarities
      commons   = cards_to_use.select { |c| c.rarity == "common"   } 
      uncommons = cards_to_use.select { |c| c.rarity == "uncommon" } 
      rares     = cards_to_use.select { |c| c.rarity == "rare"     } 
      mythics   = cards_to_use.select { |c| c.rarity == "mythic"   }     
      basics    = cards_to_use.select { |c| c.rarity == "basic"    }   
      tokens    = cards_to_use.select { |c| c.rarity == "token"    }
      if basics.empty? 
        basics = Card.basic_land 
      end
      rares_and_mythics = rares + rares + mythics 
      tokens_present = !tokens.empty?
      # if uncommons.empty? || commons.empty? || rares_and_mythics.empty?
      #   raise "Set doesn't have cards of enough rarities to assemble boosters. Commons, uncommons, and either rares or mythics are required."
      # end
      # min_commons = 11
      # min_uncommons = 3
      # if (1..min_commons-1).include? commons.length 
        # return [nil, "Not enough commons to create a diverse booster pack: we require #{ min_commons } commons, but the cardset only has #{ commons.length }."]
      # elsif (1..min_uncommons-1).include? uncommons.length 
        # return [nil, "Not enough uncommons to create a diverse booster pack: we require #{ min_uncommons } uncommons, but the cardset only has #{ uncommons.length }."]
      # end
          
      collation = booster_structure()[0]
      if rand(60) < ( collation == "m10" ? 14 : 15 )
        # got a foil
        foil_type = rand(15)
        case foil_type
          when 1 then
            foil_src = rares_and_mythics.sample
          when 2..4 then
            foil_src = uncommons.sample
          else
            foil_src = commons.sample 
        end
        if foil_src.nil?
          foil = nil
        else
          foil = foil_src.clone # so that if the unfoil one is in the booster too, that isn't foiled
          foil.foil = true
        end
      else
        foil = nil
      end
      num_booster_commons = ( collation=="m10" ? 10 : 11 ) - ( foil.nil? ? 0 : 1 )

      if foil
        @booster << foil
      end
      if rares_and_mythics.empty?
        chosen_rare = Card.blank("No more rares or mythics")
      else
        chosen_rare = rares_and_mythics.sample
      end
      @booster << chosen_rare
      chosen_uncommons = []
      while chosen_uncommons.length < 3
        if uncommons.empty?
          chosen_uncommons << Card.blank("No more uncommons")
        else
          new_candidate = uncommons.sample
          chosen_uncommons << new_candidate 
          uncommons -= [new_candidate]
        end
      end
      @booster += chosen_uncommons
      
      # For commons we do something slightly different: we distribute the chosen points
      # evenly-ish along the list of commons
      commons.sort!
      chosen_commons = []
      top_endpoint = commons.length 
      endpoints = []
      endpoints[0] = 0
      between_endpoints = 1.0 * top_endpoint / num_booster_commons 
      (1..num_booster_commons).each do |n|
        endpoints[n] = (between_endpoints * n)
        chosen_commons[n-1] = commons[rand*between_endpoints + endpoints[n-1]]
      end
      chosen_commons.uniq! # because some groups may overlap
      chosen_commons -= [nil] # in case there are /no/ commons
      if chosen_commons.length < num_booster_commons
        # The set has rather few commons. Fill in the rest with randomly chosen ones.
        commons -= chosen_commons
        while chosen_commons.length < num_booster_commons
          if commons.empty?
            chosen_commons << Card.blank("No more commons")
          else
            new_candidate = commons.sample
            chosen_commons << new_candidate 
            commons -= [new_candidate]
          end
        end
      end
      chosen_commons.shuffle!
      
      @booster += chosen_commons
      if collation == "m10"
        @booster << basics.sample
      end
      if tokens_present
        @booster << tokens.sample
      end
    
    end
    
    data_out = [collation, tokens_present]
    return [@booster, "", data_out]
  end
  
  ########################## Importing data ##########################
  ALIASES = {
    "type" => "cardtype",
    "manacost" => "cost",
    "text" => "rulestext",
    "flavortext" => "flavourtext",
    "color" => "frame",
    "colour" => "frame",
    "notes" => "comment",
    "art" => "art_url",
    "image" => "image_url",
  }
  FIELDS = ["","name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","power","toughness","loyalty","code","frame","art_url","artist","image_url","comment","active","watermark"]
  ENUM_ALIASES = {
    "frame" => {  # keys need to be strings, not symbols
      "w" => "white", "u" => "blue", "b" => "black", "r" => "red", "g" => "green", "a" => "artifact", "z" => "multicolour", "m" => "multicolour", "l" => "land", "h" => "hybrid",
      "gold" => "multicolour", "multi" => "multicolour", "multicolor" => "multicolour", "multicolored" => "multicolour", "multicoloured" => "multicolour"
    },
    "rarity" => {
      "c" => "common", "u" => "uncommon", "r" => "rare", "m" => "mythic",
      "mythic rare" => "mythic", "mystic" => "mythic", "mythicrare" => "mythic"
    }
  }

  def import_data(params, current_user)
    # Returns [success, message, log_text, changed_cards]

    # Initial informative error messages
    @cardset = Cardset.find(params[:id])
    if params[:data].blank?
      return false, "No data supplied", "", []
    end
    if params[:formatting_line].blank?
      return false, "Formatting line is required", "", []
    end
    # Deduce separator from formatting line
    non_alpha = params[:formatting_line].split(/[a-z]/).select {|c| c=~ /^.$/}
    non_alpha.uniq!
    case non_alpha.length
      when 0
        return false, "Could not deduce CSV separator from formatting line", "", []
      when 1
        separator = non_alpha[0]
      else
        return false, "Too many non-alphabetic characters in formatting line to deduce CSV separator character. There should only be one, but I found the following: '#{non_alpha.join("','")}'", "", []
    end
    if params[:id].blank?
      return false, "No cardset ID supplied - please re-navigate to this page via the cardset", "", []
    end

    # Validate the supplied formatting line
    inputfields = params[:formatting_line].downcase.split(separator)
    canonfields = inputfields.map{ |f| ALIASES.has_key?(f) ? ALIASES[f] : f.strip }
    validfields = canonfields.select{ |f| FIELDS.include?(f) }
    if validfields != canonfields
      return false, "The following fields were not recognised: " + (canonfields - validfields).join(", "), "", []
    end

    # We need to detect and reject duplicates of any field, except "" which we allow in multiples
    uniqfields = []
    rejectfields = []
    validfields.each do |f|
      uniqfields.member?(f) && f != "" ? rejectfields <<= f : uniqfields <<= f
    end

    if !rejectfields.empty?
      return false, "The following fields were duplicated: " + rejectfields.uniq.join(", "), "", []
    end

    debug = ''

    fields = uniqfields
    got_rarity = fields.include?("rarity")
    got_comment = fields.include?("comment")
    got_type = fields.include?("cardtype")
    got_loyalty = fields.include?("loyalty")
    got_frame = fields.include?("frame")

    # Read the CSV
    # Use CSV.parse, which takes care of quoting and newlines for us
    begin
      #cardsdata = FasterCSV.parse(params[:data], :col_sep => separator);
      cardsdata = CSV.parse(params[:data], :col_sep => separator);
    rescue => e
      return false, "I'm sorry, but your CSV wasn't valid. Try splitting it into chunks and importing them separately. The error returned was: #{e.message}", "", []      
    end
    cards_and_comments = []
    skipped_cards = overwritten_cards = new_cards = 0

    cardsdata.each_with_index do |carddata, index|
      # Allow completely blank lines
      if carddata.nil? || carddata == [nil]
        next
      end
      if carddata.length != fields.length
        # Give a nice error message, with 1-based indexing
        return false, "Line #{index+1} of data had #{carddata.length} fields when expecting #{fields.length}", "", []
      end

      carddatahash = Hash[fields.zip(carddata)]
      # We allow empty strings, to let the data include other values, but we don't want to include them in the post
      if carddatahash.has_key?("")
        carddatahash.delete("")
      end
      # Translate "R" -> "Rare", etc
      ENUM_ALIASES.keys.each do |field|
        if !carddatahash[field].nil?
          inputval = carddatahash[field].downcase
          carddatahash[field] = ENUM_ALIASES[field].has_key?(inputval) ? ENUM_ALIASES[field][inputval] : inputval
        end
      end
  
      # Remove the comment from the card data, as we do something different with the comment
      if got_comment
        comment = carddatahash.delete("comment")
      end
      # Loyalty is stored internally as toughness, so if a card has loyalty but no toughness, move loyalty to toughness
      if got_loyalty
        if carddatahash["toughness"].blank? && !carddatahash["loyalty"].blank?
          carddatahash["toughness"] = carddatahash["loyalty"]
        end
        carddatahash.delete("loyalty")
      end
      # Capitalize frame/colour
      if got_frame
        carddatahash["frame"] && carddatahash["frame"].capitalize!
      end

      # Obtain the existing card
      if params[:duplicates] == "duplicate"
        # Always just create a new card
        new_cards+=1
        card = @cardset.cards.build(carddatahash)
      else
        # See if there's an existing card
        existing_card = !carddatahash["code"].blank? && @cardset.cards.find_by_code(carddatahash["code"])
        if !existing_card
          existing_card = !carddatahash["name"].blank? && @cardset.cards.find_by_name(carddatahash["name"])
        end
        if !existing_card
          # Just create a new card
          new_cards+=1
          card = @cardset.cards.build(carddatahash)
        else
          if params[:duplicates] == "preserve"
            skipped_cards+=1
            next # Skip this loop iteration and ignore this card completely
          elsif params[:duplicates] == "replace"
            # Overwrite this card with the new card
            overwritten_cards+=1
            Rails.logger.info "Updating #{carddatahash['name']} with new data"
            card = existing_card
            # Don't use update_attributes, because we don't want to save! the card yet
            card.attributes = carddatahash
          else
            raise "Unknown option for 'duplicates' parameter: #{params[:duplicates]}"
          end
        end
      end

      # Don't save the card yet, since there may be a parse error on later lines
      if got_comment && !comment.blank?
        cards_and_comments << [card, comment]
      else
        cards_and_comments << [card, nil]
      end
      Rails.logger.info "Imported card #{card.printable_name}"
    end

    # We've not returned so far, so the whole data must be good
    cards_and_comments.each do |card_and_comment|
      card = card_and_comment[0]
      card.frame = card.frame.blank? ? card.calculated_frame : card.frame
      commenttext = card_and_comment[1]
      card.save!
      if !commenttext.blank?
        comment = card.comments.build(:user => current_user, :body => commenttext)
        comment.save!
      end
    end

    # Returns [success, message, log_text, changed_cards]
    message = "Data was successfully imported! "
    skipped_cards>0 && message << (skipped_cards == 1 ? "#{skipped_cards} card was left unchanged. " : "#{skipped_cards} cards were left unchanged. ")
    overwritten_cards>0 && message << (overwritten_cards == 1 ? "#{overwritten_cards} card was updated. " : "#{overwritten_cards} cards were updated. ")
    new_cards>0 && message << (new_cards == 1 ? "#{new_cards} new card was added. " : "#{new_cards} new cards were added. ")
    log_text = "#{new_cards} created, #{overwritten_cards} updated"
    return true, message, log_text, cards_and_comments.map { |card, comment| card }
  end
  
  def update_timestamp_from_logs
    self.updated_at = self.recent_action.updated_at
    self.save!
  end
  
end
