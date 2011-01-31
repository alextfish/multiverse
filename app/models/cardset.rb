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
  belongs_to :user
  has_many :cards, :dependent => :destroy
  has_many :admins, :class_name => "User"
  has_many :details_pages, :dependent => :destroy
  has_many :mechanics, :dependent => :destroy 
  has_one :configuration, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :logs

  validates_length_of :name, :within => 2..40

  def get_stats
    out = {}
    out[:by_category] = Hash.new(0)
    out[:by_rarity] = Hash.new(0)
    cards.each do |card|
      out[:by_category][card.category || "unspecified"] += 1
      out[:by_rarity][card.rarity || "unspecified"] += 1
    end
    out
  end

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
  
  def log(in_hash)
    self.logs.create :kind=>Log.kind(in_hash[:kind]), 
                     :datestamp=>Time.now, 
                     :user=>in_hash[:user], 
                     :object_id=>in_hash[:object_id],
                     :text=>in_hash[:text]
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
  
  def recent_action
    self.logs.first
  end
  def datestamps_close(d1,d2)
    (d1-d2).abs < 20.seconds
  end
  def make_logs_v2
    updated_card_comment_logs = 0
    new_card_comment_logs = 0
    updated_cardset_comment_logs = 0
    new_cardset_comment_logs = 0
  
    comment_card = Log.kind(:comment_card)
    comment_cardset = Log.kind(:comment_cardset)
    comment_edit = Log.kind(:comment_edit)
    self.cards.each do |card|
      card.comments.each do |comment|
        # find creation
        orig_create_log = self.logs.select { |l| l.kind == comment_card &&
                         datestamps_close(l.datestamp, comment.created_at) &&
                         l.user == comment.user }[0]
        if orig_create_log
          updated_card_comment_logs += 1
          orig_create_log.object_id = comment.id
          orig_create_log.save
        else
          new_card_comment_logs += 1
          self.logs.create :kind => comment_card,
                           :datestamp => comment.created_at, 
                           :user => comment.user,
                           :object_id => comment.id,
                           :text => "created by make_logs_v2"
        end
        
        # if !datestamps_close(comment.created_at, comment.updated_at)
          # # find edit
          # orig_update_log = self.logs.select { |l| l.kind == comment_edit &&
                           # datestamps_close(l.datestamp, comment.updated_at) &&
                           # l.user == comment.user }[0]
          # if orig_update_log
            # updated_card_comment_logs += 1
            # orig_update_log.object_id = comment.id
            # orig_update_log.save
          # else
            # new_card_comment_logs += 1
            # self.logs.create :kind => comment_edit,
                             # :datestamp => comment.updated_at, 
                             # :user => comment.user,
                             # :object_id => comment.id
          # end
        # end
      end
    end
    self.comments.each do |comment|
      # find creation
      orig_create_log = self.logs.select { |l| l.kind == comment_cardset &&
                       datestamps_close(l.datestamp, comment.created_at) &&
                       l.user == comment.user }[0]
      if orig_create_log
        updated_cardset_comment_logs += 1
        orig_create_log.object_id = comment.id
        orig_create_log.save
      else
        new_cardset_comment_logs += 1
        self.logs.create :kind => comment_cardset,
                         :datestamp => comment.created_at, 
                         :user => comment.user,
                         :object_id => comment.id,
                         :text => "created by make_logs_v2"
      end
      
      # if !datestamps_close(comment.created_at, comment.updated_at)
        # # find update
        # orig_update_log = self.logs.select { |l| l.kind == comment_edit &&
                         # datestamps_close(l.datestamp, comment.updated_at) &&
                         # l.user == comment.user }[0]
        # if orig_update_log
          # updated_cardset_comment_logs += 1
          # orig_update_log.object_id = comment.id
          # orig_update_log.save
        # else
          # new_cardset_comment_logs += 1
          # self.logs.create :kind => comment_edit,
                           # :datestamp => comment.updated_at, 
                           # :user => comment.user,
                           # :object_id => comment.id
        # end
      # end
    end
    Rails.logger.info "Updated #{self.name} logs: card comment logs new #{new_card_comment_logs}, updated #{updated_card_comment_logs}; cardset comment logs new #{new_cardset_comment_logs}, updated #{updated_cardset_comment_logs}"
  end
  
  ########################## Skeletons #########################  
  def skeleton
    self.details_pages.select{|dp| dp.title == "Skeleton" }[0]
  end
  
  def Cardset.skeleton_line_regexp_MD
    /^\(\(\(([CURM])([A-Z])([0-9][0-9])/
  end
  def Cardset.skeleton_line_regexp_HTML
    /(?:>[(]?)([CURM])([A-Z])([0-9][0-9])/
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
      %w{C U R M}.each do |rarity_letter|
        params["skeletonform_#{colour}_rarity#{rarity_letter}"] = params["skeletonform_white_rarity#{rarity_letter}"]
      end
    end

    # For each frame-rarity combo (which all start with skeletonform_):
    rarity_frame_regexp = /skeletonform_([a-z]*)_rarity([A-Z])/
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
        when "white": frame_letter = "W"
        when "blue": frame_letter = "U"
        when "black": frame_letter = "B"
        when "red": frame_letter = "R"
        when "green": frame_letter = "G"
        when "artifact": frame_letter = "A"
        when "land": frame_letter = "L"
        when "allygold": frame_letter = "Z"; number_in *= 5
        when "enemygold": frame_letter = "Z"; number_in *= 5
        when "allyhybrid": frame_letter = "H"; number_in *= 5
        when "enemyhybrid": frame_letter = "H"; number_in *= 5
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
            when "C": []
            when "U": existing_codes_this_frame.select {|code| code[0]==?C}
            when "R": existing_codes_this_frame.select {|code| [?C,?U].include? code[0]}
            when "M": existing_codes_this_frame # already established there are no mythics
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
    
    # now handle the insertions
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
    rarity_offsets = {"C" => 0, "U" => 0.01, "R" => 0.02, "M" => 0.03}
    insertions.sort_by {|codes, line_num| line_num + rarity_offsets[codes[0][0].chr] + frame_offsets[codes[0][1].chr]}.reverse_each do |codes, line_num|
      # To insert lines for [a b c] at position 5, we insert c at 5, then b at 5, then a at 5
      codes.reverse.each do |code|
        new_line = "(((#{code})))" + (" | " * number_of_bars) + "\n"
        lines_out.insert line_num, new_line
      end
    end
    
    # Now lines_out contains the new skeleton body
    # Existing lines and inserted lines all end with "\n", so we just join() them
    if @skeleton.nil?
      @skeleton = self.details_pages.build(:title => "Skeleton")
      lines_out = ["|Code | Slot | Card name |\n", "|:---:|------|---------|\n"] + lines_out
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
      when "prettycard": 5
      when "plain": 2
      when "image": 3
    end
  end

  def make_booster()
    commons   = self.cards.select { |c| c.rarity == "common" } 
    uncommons = self.cards.select { |c| c.rarity == "uncommon" } 
    rares     = self.cards.select { |c| c.rarity == "rare" } 
    mythics   = self.cards.select { |c| c.rarity == "mythic" }     
    basics    = self.cards.select { |c| c.rarity == "basic" }   
    tokens    = self.cards.select { |c| c.rarity == "token" }
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
      
    @m10_collation = mythics.any?
    if rand(60) < ( @m10_collation  ? 14 : 15 )
      # got a foil
      foil_type = rand(15)
      case foil_type
        when 1:
          foil_src = rares_and_mythics.choice
        when 2..4:
          foil_src = uncommons.choice
        else
          foil_src = commons.choice 
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
    num_booster_commons = ( @m10_collation ? 10 : 11 ) - ( foil.nil? ? 0 : 1 )

    @booster = []
    if foil
      @booster << foil
    end
    if rares_and_mythics.empty?
      chosen_rare = Card.blank("No more rares or mythics")
    else
      chosen_rare = rares_and_mythics.choice
    end
    @booster << chosen_rare
    chosen_uncommons = []
    while chosen_uncommons.length < 3
      if uncommons.empty?
        chosen_uncommons << Card.blank("No more uncommons")
      else
        new_candidate = uncommons.choice
        chosen_uncommons << new_candidate 
        uncommons -= [new_candidate]
      end
    end
    @booster += chosen_uncommons
    
    # For commons we do something slightly different: we distribute the chosen points
    # evenly-ish along the list of commons
    commons.sort!
    chosen_commons = []
    while chosen_commons.length < num_booster_commons
      if commons.empty?
        chosen_commons << Card.blank("No more commons")
      else
        new_candidate = commons.choice
        chosen_commons << new_candidate 
        commons -= [new_candidate]
      end
    end
    @booster += chosen_commons
    if @m10_collation
      @booster << basics.choice
    end
    if tokens_present
      @booster << tokens.choice
    end
    
    data_out = [@m10_collation, tokens_present]
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
  FIELDS = ["","name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","power","toughness","loyalty","code","frame","art_url","artist","image_url","comment","active"]
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
  SUPERTYPES_AND_REGEXPS = Card.supertypes.map do |supertype|
    [supertype, Regexp.new(supertype, true)]   # true -> case-insensitive
  end
  SUBTYPE_DELIMITERS = [" -- ", " - ", "--", "-"]

  def import_data(params, current_user)
    # Returns [success, message, log_text, changed_cards]

    # Initial informative error messages
    @cardset = Cardset.find(params[:id])
    if params[:separator].blank?
      return false, "Separator character is required", "", []
    end
    if params[:formatting_line].blank?
      return false, "Formatting line is required", "", []
    end
    if params[:data].blank?
      return false, "No data supplied", "", []
    end
    if params[:id].blank?
      return false, "No cardset ID supplied - please re-navigate to this page via the cardset", "", []
    end

    # Validate the supplied formatting line
    inputfields = params[:formatting_line].downcase.split(params[:separator])
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
      cardsdata = CSV.parse(params[:data], params[:separator]);
    rescue CSV::IllegalFormatError => ie
      return false, "I'm sorry, but your CSV wasn't valid. Try splitting it into chunks and importing them separately.", "", []      
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
      if got_type
        Rails.logger.info "cardtype is #{carddatahash['cardtype']}"
        # Move supertypes to correct places
        SUPERTYPES_AND_REGEXPS.each do |supertype, regexp|
          if carddatahash["cardtype"].downcase =~ regexp
            carddatahash["supertype"] =  (carddatahash["supertype"] || "") + " " + supertype
            carddatahash["cardtype"].slice!(regexp)
          end
        end
        # Move subtypes to correct places
        SUBTYPE_DELIMITERS.each do |delimiter|
          if carddatahash["cardtype"].include?(delimiter) && carddatahash["subtype"].blank?
            carddatahash["cardtype"], carddatahash["subtype"] = carddatahash["cardtype"].split(delimiter)
          end
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
            Rails.logger.info "Overwriting #{carddatahash['name']} with its new version"
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
end
