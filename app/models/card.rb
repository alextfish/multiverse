# == Schema Information
# Schema version: 20100926114339
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
#

class Card < ActiveRecord::Base
  belongs_to :cardset
  has_many :comments, :dependent => :destroy
  has_many :old_cards, :dependent => :destroy


  #has_many :highlighted_comments, :class_name => 'Comment', :conditions => ['status = ?', Comment.HIGHLIGHTED]
  #has_many :unaddressed_comments, :class_name => 'Comment', :conditions => ['status = ?', Comment.UNADDRESSED]

  def formatted_rules_text
    format(rulestext)
  end
  def formatted_flavour_text
    format(flavourtext)
  end

  def calculated_frame
    colour_regexps = [/w/i, /u/i, /b/i, /r/i, /g/i]
    nonhybrid_colour_regexps = [/(^|[^\/{(])w/i,  # match w either at the start ^, or after anything other than / { (
                                /(^|[^\/{(])u/i,
                                /(^|[^\/{(])b/i,
                                /(^|[^\/{(])r/i,
                                /(^|[^\/{(])g/i]

    colours_in_cost = colour_regexps.map do |re|
      re.match(cost) ? true : false
    end
    num_colours = colours_in_cost.count{|x|x}


    def card_colours
      ["White", "Blue", "Black", "Red", "Green"]
    end

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
        colours_present = nonhybrid_colour_regexps.reduce(0) do |total, re|
          re.match(cost) ? total+1 : total
        end
        if colours_present >= 2
          return "Multicolour"
        else
          colour_strings_present = (colour_regexps.zip(card_colours)).map do |re, colour|
            re.match(cost) ? colour : nil
          end
          return "Hybrid " + colour_strings_present.compact.join("-")
        end
      when 3..5:  # Multicolour is easy
        return "Multicolour"
      when 0:     # Colourless is either artifact, land, or neither, based on type
        if /artifact/i.match(cardtype)
          return "Artifact"
        elsif !/land/i.match(cardtype)
          return "Colourless"
        else      # Land
          # Could try to detect the text box here, but that's really fiddly to get right
          # Consider Coastal Tower, Arcane Sanctum, Hallowed Fountain, Flooded Strand, and Vivid Creek
          # So we just let them override it
          return "Land (colourless)"
        end
    end
  end

end
