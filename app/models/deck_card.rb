class DeckCard < ActiveRecord::Base
  belongs_to :card
  belongs_to :decklist
  
  validates :count, :positive
  
end
