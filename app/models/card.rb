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

  def formatted_rules_text
    format(rulestext)
  end
  def formatted_flavour_text
    format(flavourtext)
  end
end
