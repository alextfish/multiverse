# == Schema Information
# Schema version: 20101103224310
#
# Table name: cards
#
#  id          :integer         not null, primary key
#  code        :string(255)
#  name        :string(255)
#  cardset_id  :integer
#  colour      :string(255)
#  rarity      :string(255)
#  cost        :string(255)
#  supertype   :string(255)
#  cardtype    :string(255)
#  subtype     :string(255)
#  rulestext   :text
#  flavourtext :text
#  power       :integer
#  toughness   :integer
#  image       :string(255)
#  active      :boolean
#  created_at  :datetime
#  updated_at  :datetime
#  frame       :string(255)
#

class Card < ActiveRecord::Base
  belongs_to :cardset
  has_many :comments, :dependent => :destroy
  has_many :old_cards, :dependent => :destroy


  #has_many :highlighted_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_HIGHLIGHTED]
  #has_many :unaddressed_comments, :class_name => 'Comment', :conditions => ['status = ?', COMMENT_UNADDRESSED]

<<<<<<< HEAD
  before_create :regularise_fields
  #after_save do  - Can't do this, as we don't have access to session methods in model callbacks :/
  #  set_last_edit(self)
  #end

  DEFAULT_RARITY = "common"
  STRING_FIELDS = ["name","cost","supertype","cardtype","subtype","rarity","rulestext","flavourtext","code","colour","art_url","artist","image_url"]
  def regularise_fields
    # Enforce rarity; Default rarity to common
    if (self.rarity.blank?) || !Card.rarities.include?(self.rarity)
      self.rarity = DEFAULT_RARITY
    end
    # Strip whitespace
    STRING_FIELDS.each do |field|
      if self.attributes[field]
        self.attributes[field].strip!
      end
    end
  end

=======
>>>>>>> parent of 234dee4... Don't reset rarity when partial-importing
  def formatted_rules_text
    format(rulestext)
  end
  def formatted_flavour_text
    format(flavourtext)
  end

  def recency  # For a card, its order in recency is when it was updated
    updated_at
  end

  def self.colours
    ["White", "Blue", "Black", "Red", "Green"]
  end

  def self.frames
    Card.colours + ["Artifact", "Multicolour", "Colourless"] +
    Card.colour_pairs.map { |pair| "Hybrid #{pair.join("-").downcase}" } +
    ["Land (colourless)"] +
    Card.colours.map { |col| "Land (#{col.downcase})" } +
    Card.colour_pairs.map { |pair| "Land (#{pair.join('-').downcase})" } +
    ["Land (multicolour)"]
  end
  def self.colour_pairs
    Card.colours.combination(2).to_a
  end

  def self.rarities
    ["common", "uncommon", "rare", "mythic"]
  end
  def self.supertypes
    ["Legendary", "Basic", "World", "Snow"]
  end
  def self.category_order
    ["Colourless", "White", "Blue", "Black", "Red", "Green", "Multicolour", "Hybrid", "Artifact", "Land"]
  end
  @@colour_regexps = [/w/i, /u/i, /b/i, /r/i, /g/i]
  @@nonhybrid_colour_regexps = [
      /(^|[^\/{(])w/i,  # match w either at the start ^, or after anything other than / { (
      /(^|[^\/{(])u/i,
      /(^|[^\/{(])b/i,
      /(^|[^\/{(])r/i,
      /(^|[^\/{(])g/i]

  def colours_in_cost
    out = @@colour_regexps.map do |re|
      re.match(cost) ? true : false
    end
  end
  def num_colours
    colours_in_cost.count{|x|x}
  end
  def colour_strings_present
    out = (@@colour_regexps.zip(Card.colours)).map do |re, colour|
      re.match(cost) ? colour : nil
    end.compact
  end

  def category
    f = calculated_frame
    case f
      when /^Land/
        return "Land"
      when /^(White|Blue|Black|Red|Green|Multicolour|Artifact|Colourless)$/:
        return f
      when /^Hybrid/
        return "Hybrid"
    end
  end

  def <=>(c2)
    if category != c2.category
      # Sort by category
      return Card.category_order.find_index(category) <=> Card.category_order.find_index(c2.category)
    else
      if ["Multicolour", "Hybrid"].include?(category)
        # Within a category, sort by colour-pair (hybrid / gold), then name
        if num_colours == c2.num_colours
          case num_colours
            when 2
              pair_order = ["WhiteBlue", "BlueBlack", "BlackRed", "RedGreen", "WhiteGreen",
                "WhiteBlack", "BlackGreen", "BlueGreen", "BlueRed", "WhiteRed"
                ]
            when 3
              pair_order = [ # allied triples sorted by Shard order
                "WhiteBlueBlack", "BlueBlackRed", "BlackRedGreen", "WhiteRedGreen", "WhiteBlueGreen",
                # enemy triples sorted by the mutual enemy
                "WhiteBlackRed", "BlueRedGreen", "WhiteBlackGreen", "WhiteBlueRed", "BlueBlackGreen"
                ]
            when 4
              pair_order = [ "WhiteBlueBlackRed", "BlueBlackRedGreen", "WhiteBlackRedGreen", "WhiteBlueRedGreen", "WhiteBlueBlackGreen" ]
          end
          pair1 = colour_strings_present.join
          pair2 = c2.colour_strings_present.join
          if pair1 != pair2
            return pair_order.find_index(pair1) <=> pair_order.find_index(pair2)
          else
            # Just sort by name
            return name <=> c2.name
          end
        else
          # Higher number of colours goes later
          if num_colours != c2.num_colours
            return num_colours <=> c2.num_colours
          else
            # Just sort by name
            return name <=> c2.name
          end
        end
      else
        # Within a category other than multicolour, just sort by name
        return name <=> c2.name
      end
    end
  end


  def calculated_frame

    case num_colours
      when 1:     # Monocolour is the simplest case
        case cost
          when /w/i: return "White"
          when /u/i: return "Blue"
          when /b/i: return "Black"
          when /r/i: return "Red"
          when /g/i: return "Green"
        end
      when 2:     # Two-colour: distinguish between gold and hybrid
                  # We say a card for 1W(W/U)U is gold, but 1W(W/G) is hybrid
        # Count the number of colours present outside hybrid symbols
        colours_present = @@nonhybrid_colour_regexps.reduce(0) do |total, re|
          re.match(cost) ? total+1 : total
        end
        if colours_present >= 2
          return "Multicolour"
        else
          return "Hybrid " + colour_strings_present.join("").downcase
        end
      when 3..5:  # Multicolour is easy
        return "Multicolour"
      when 0:     # Colourless is either artifact, land, or neither, based on type
        if /land/i.match(cardtype) # Land
          # Could try to detect the text box here, but that's really fiddly to get right
          # Consider Coastal Tower, Arcane Sanctum, Hallowed Fountain, Flooded Strand, and Vivid Creek
          # So we just let them override it
          return "Land (colourless)"
        elsif /artifact/i.match(cardtype)
          return "Artifact"
        else
          return "Colourless"
        end
    end
  end

end
