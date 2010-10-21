# == Schema Information
# Schema version: 20100926114339
#
# Table name: cardsets
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  user_id     :integer
#  description :text
#  created_at  :datetime
#  updated_at  :datetime


require 'csv'

class Cardset < ActiveRecord::Base
  attr_accessible :name, :description
  belongs_to :user
  has_many :cards, :dependent => :destroy
  has_many :admins, :class_name => "User"

  def get_stats
    out = {}
    out[:by_colour] = Hash.new(0)
    out[:by_rarity] = Hash.new(0)
    cards.each do |card|
      out[:by_colour][card.colour] += 1
      out[:by_rarity][card.rarity] += 1
    end
    out
  end


  ALIASES = {
    "type" => "cardtype",
    "manacost" => "cost",
    "text" => "rulestext",
    "flavortext" => "flavourtext",
    "color" => "colour",
    "notes" => "comment"
  }
  FIELDS = ["","name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","power","toughness","loyalty","code","colour","comment"]
  STRING_FIELDS = ["name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","code","colour","comment"]
  DEFAULT_RARITY = "common"
  ENUM_ALIASES = {
    "colour" => {  # keys need to be strings, not symbols
      "w" => "white", "u" => "blue", "b" => "black", "r" => "red", "g" => "green", "a" => "artifact", "z" => "multicolour", "l" => "land",
      "gold" => "multicolour", "multi" => "multicolour", "multicolor" => "multicolour", "multicolored" => "multicolour", "multicoloured" => "multicolour"
    },
    "rarity" => {
      "c" => "common", "u" => "uncommon", "r" => "rare", "m" => "mythic",
      "mythic rare" => "mythic", "mystic" => "mythic", "mythicrare" => "mythic"
    }
  }
  SUPERTYPES = ["Legendary", "Basic", "World", "Snow"]
  SUPERTYPES_AND_REGEXPS = SUPERTYPES.map do |supertype|
    [supertype, Regexp.new(supertype, true)]   # true -> case-insensitive
  end


  def import_data(params)
    # Returns [success, message]

    # Initial informative error messages
    @cardset = Cardset.find(params[:id])
    if params[:separator].blank?
      return false, "Separator character is required"
    end
    if params[:formatting_line].blank?
      return false, "Formatting line is required"
    end
    if params[:data].blank?
      return false, "No data supplied"
    end
    if params[:id].blank?
      return false, "No cardset ID supplied - please re-navigate to this page via the cardset"
    end

    # Validate the supplied formatting line
    inputfields = params[:formatting_line].downcase.split(params[:separator])
    canonfields = inputfields.map{ |f| ALIASES.has_key?(f) ? ALIASES[f] : f.strip }
    validfields = canonfields.select{ |f| FIELDS.include?(f) }
    if validfields != canonfields
      return false, "The following fields were not recognised: " + (canonfields - validfields).join(", ")
    end

    # We need to detect and reject duplicates of any field, except "" which we allow in multiples
    uniqfields = []
    rejectfields = []
    validfields.each do |f|
      uniqfields.member?(f) && f != "" ? rejectfields <<= f : uniqfields <<= f
    end

    if !rejectfields.empty?
      return false, "The following fields were duplicated: " + rejectfields.uniq.join(", ")
    end

    debug = ''

    fields = uniqfields
    got_rarity = fields.include?("rarity")
    got_comment = fields.include?("comment")

    # Read the CSV
    # Use CSV.parse, which takes care of quoting and newlines for us
    cardsdata = CSV.parse(params[:data], params[:separator]);
    cards = []
    cardsdata.each_with_index do |carddata, index|
      if carddata.length != fields.length
        # Give a nice error message, with 1-based indexing
        return false, "Line #{index+1} of data had #{carddata.length} fields when expecting #{fields.length}"
      end

      carddatahash = Hash[fields.zip(carddata)]
      # We allow empty strings, to let the data include other values, but we don't want to include them in the post
      if carddatahash.has_key?("")
        carddatahash.delete("")
      end
      # Default rarity to common
      if !got_rarity
        carddatahash[:rarity] = DEFAULT_RARITY
      end
      # Translate "R" -> "Rare", etc
      ENUM_ALIASES.keys.each do |field|
        if !carddatahash[field].nil?
          inputval = carddatahash[field].downcase
          carddatahash[field] = ENUM_ALIASES[field].has_key?(inputval) ? ENUM_ALIASES[field][inputval] : inputval
        end
      end
      # Move supertypes to correct places
      SUPERTYPES_AND_REGEXPS.each do |supertype, regexp|
        if carddatahash["cardtype"].downcase =~ regexp
          carddatahash["supertype"] =  (carddatahash["supertype"] || "") + " " + supertype
          carddatahash["cardtype"].slice!(regexp)
        end
      end
      # Strip whitespace
      STRING_FIELDS.each do |field|
        carddatahash[field] && carddatahash[field].strip!
      end

      debug += "Fields are now: #{carddatahash.inspect}\n"


      if got_comment
        comment = carddatahash.delete[:comment]
      end
      card = @cardset.cards.build(carddatahash)

      # Don't save the card yet, since there may be a parse error on later lines
      if got_comment && !comment.blank?
        cards << [card, comment]
      else
        cards << [card, nil]
      end
    end

    # We've not returned so far, so the whole data must be good
    cards.each do |cardandcomment|
      card = cardandcomment[0]
      commenttext = cardandcomment[1]
      card.save!
      if !commenttext.nil?
        comment = card.comments.build(:user => current_user, :comment => commenttext)
        comment.save!
      end
    end

    return true, 'Data was successfully imported!' + (Rails.env.development? ? debug : '')
  end
end
