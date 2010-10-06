# == Schema Information
# Schema version: 20100926114339
#
# Table name: old_cards
#
#  id          :integer         not null, primary key
#  card_id     :integer
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
#  posttime    :datetime
#  created_at  :datetime
#  updated_at  :datetime
#

class OldCard < ActiveRecord::Base
  belongs_to :card
end
