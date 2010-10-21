class AddIndicesToCardsAndCardset < ActiveRecord::Migration
  def self.up
    add_index :cards, :cardset_id
    add_index :comments, :card_id
  end

  def self.down
    remove_index :cards, :cardset_id
    remove_index :comments, :card_id
  end
end
