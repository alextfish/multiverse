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

  FORMAT_SUBSTITUTIONS = {
    "\n" => "<br>",
    /\bUEOT\b/i => "until end of turn",
    /\bETBs\b/ => "enters the battlefield",
    /\bETB\b/ => "enter the battlefield",
    /\bCIPs\b/ => "comes into play",
    /\bCIP\b/ => "come into play",
  }
  CARDNAME_ALIASES = ['CARDNAME', '~this~', '~']

  def format(text)
    # Output is marked as HTML_safe - this is a SECURITY RISK unless input text is html_escape'd.
    # I'd do that myself, but this function's in the card model, and html_escape is only available in ERB...
    if text
      out = FORMAT_SUBSTITUTIONS.reduce(text) do |memo, (match, replace)|
        memo.gsub(match, replace)
      end
      CARDNAME_ALIASES.each do |string|
        out.gsub!(string, name)
      end
      return out.html_safe
    end
  end

  def formatted_rules_text
    format(rulestext)
  end
  def formatted_flavour_text
    format(flavourtext)
  end
end
