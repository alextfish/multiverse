class CreateOldCards < ActiveRecord::Migration
  def self.up
    create_table :old_cards do |t|
      t.integer :card_id
      t.string :name
      t.integer :cardset_id
      t.string :colour
      t.string :rarity
      t.string :cost
      t.string :supertype
      t.string :cardtype
      t.string :subtype
      t.text :rulestext
      t.text :flavourtext
      t.integer :power
      t.integer :toughness
      t.datetime :posttime

      t.timestamps
    end
  end

  def self.down
    drop_table :old_cards
  end
end
