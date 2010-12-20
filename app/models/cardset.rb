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
    if basics.empty? 
      basics = Card.basic_land 
    end
    rares_and_mythics = rares + rares + mythics 
    # if uncommons.empty? || commons.empty? || rares_and_mythics.empty?
    #   raise "Set doesn't have cards of enough rarities to assemble boosters. Commons, uncommons, and either rares or mythics are required."
    # end
    min_commons = 11
    min_uncommons = 3
    if (1..min_commons-1).include? commons.length 
      return [nil, "Not enough commons to create a diverse booster pack: we require #{ min_commons } commons, but the cardset only has #{ commons.length }."]
    elsif (1..min_uncommons-1).include? uncommons.length 
      return [nil, "Not enough uncommons to create a diverse booster pack: we require #{ min_uncommons } uncommons, but the cardset only has #{ uncommons.length }."]
    end
      
    @m10_collation = mythics.any?
    if rand(60) < ( @m10_collation  ? 14 : 15 )
      # got a foil
      foil_type = rand(15)
      case foil_type
        when 1:
          foil = rares_and_mythics.choice
        when 2..4:
          foil = uncommons.choice
        else
          foil = commons.choice 
      end
      foil.foil = true
    else
      foil = nil
    end
    num_booster_commons = ( @m10_collation ? 10 : 11 ) - ( foil.nil? ? 0 : 1 )

    @booster = []
    if foil
      @booster << foil
    end
    @booster << rares_and_mythics.choice
    chosen_uncommons = []
    while chosen_uncommons.length < 3
      new_candidate = uncommons.choice
      if !chosen_uncommons.include? new_candidate 
        chosen_uncommons << new_candidate 
      end
    end
    @booster += chosen_uncommons
    
    # For commons we do something slightly different: we distribute the chosen points
    # evenly-ish along the list of commons
    commons.sort!
    chosen_commons = []
    while chosen_commons.length < num_booster_commons
      new_candidate = commons.choice
      if !chosen_commons.include? new_candidate 
        chosen_commons << new_candidate 
      end
    end
    @booster += chosen_commons
    if @m10_collation
      @booster << basics.choice
    end
    data_out = [@m10_collation]
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
  FIELDS = ["","name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","power","toughness","loyalty","code","frame","art_url","artist","image_url","comment"]
  ENUM_ALIASES = {
    "frame" => {  # keys need to be strings, not symbols
      "w" => "white", "u" => "blue", "b" => "black", "r" => "red", "g" => "green", "a" => "artifact", "z" => "multicolour", "l" => "land", "h" => "hybrid",
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
    # Returns [success, message]

    # Initial informative error messages
    @cardset = Cardset.find(params[:id])
    if params[:separator].blank?
      return false, "Separator character is required", []
    end
    if params[:formatting_line].blank?
      return false, "Formatting line is required", []
    end
    if params[:data].blank?
      return false, "No data supplied", []
    end
    if params[:id].blank?
      return false, "No cardset ID supplied - please re-navigate to this page via the cardset", []
    end

    # Validate the supplied formatting line
    inputfields = params[:formatting_line].downcase.split(params[:separator])
    canonfields = inputfields.map{ |f| ALIASES.has_key?(f) ? ALIASES[f] : f.strip }
    validfields = canonfields.select{ |f| FIELDS.include?(f) }
    if validfields != canonfields
      return false, "The following fields were not recognised: " + (canonfields - validfields).join(", "), []
    end

    # We need to detect and reject duplicates of any field, except "" which we allow in multiples
    uniqfields = []
    rejectfields = []
    validfields.each do |f|
      uniqfields.member?(f) && f != "" ? rejectfields <<= f : uniqfields <<= f
    end

    if !rejectfields.empty?
      return false, "The following fields were duplicated: " + rejectfields.uniq.join(", "), []
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
    cardsdata = CSV.parse(params[:data], params[:separator]);
    cards_and_comments = []
    skipped_cards = overwritten_cards = new_cards = 0

    cardsdata.each_with_index do |carddata, index|
      # Allow completely blank lines
      if carddata.nil? || carddata == [nil]
        next
      end
      if carddata.length != fields.length
        # Give a nice error message, with 1-based indexing
        return false, "Line #{index+1} of data had #{carddata.length} fields when expecting #{fields.length}", []
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
        existing_card = carddatahash["code"] && @cardset.cards.find_by_code(carddatahash["code"])
        if existing_card.nil?
          existing_card = carddatahash["name"] && @cardset.cards.find_by_name(carddatahash["name"])
        end
        if existing_card.nil?
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
      Rails.logger.info "Imported card #{card.name}"
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

    message = "Data was successfully imported! "
    skipped_cards>0 && message << "#{skipped_cards} cards were left unchanged. "
    overwritten_cards>0 && message << "#{overwritten_cards} cards were updated. "
    new_cards>0 && message << "#{new_cards} new cards were added. "
    return true, message, cards_and_comments.map { |card, comment| card }
  end
end
