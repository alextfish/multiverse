class CreateDecklists < ActiveRecord::Migration
  def self.up
    create_table :decklists do |t|
      t.string :name 
      t.references :user
      t.references :cardset
      t.integer :status
      t.text :stats 

      t.timestamps
    end
    add_index :decklists, :user_id
    add_index :decklists, :cardset_id
    
    create_table :deck_cards do |t|
      t.references :card
      t.references :decklist
      t.integer :count
      t.integer :status 
    end
    add_index :deck_cards, :card_id
    add_index :deck_cards, :decklist_id
  end

  def self.down
    drop_table :decklists
    drop_table :deck_cards
  end
end
