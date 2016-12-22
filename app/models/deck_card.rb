class DeckCard < ActiveRecord::Base
  belongs_to :card
  belongs_to :decklist
  
  validates_numericality_of  :count, :only_integer => true, :greater_than_or_equal_to => 0
  
  validates :card_id, presence: true
  validates :decklist_id, presence: true
end
