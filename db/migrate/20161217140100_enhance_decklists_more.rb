class EnhanceDecklistsMore < ActiveRecord::Migration
  def change
    add_index :deck_cards, [:card_id, :decklist_id], unique: true
    add_index :deck_wizards_cards, [:gatherer_id, :decklist_id], unique: true
  end
end
