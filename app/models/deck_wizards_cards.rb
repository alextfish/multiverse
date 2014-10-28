class DeckWizardsCards < ActiveRecord::Base
  belongs_to :decklist
  
  validates_numericality_of  :count, :only_integer => true, :greater_than_or_equal_to => 1
end
