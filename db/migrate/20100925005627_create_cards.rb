class CreateCards < ActiveRecord::Migration
  def self.up
    create_table :cards do |t|
      t.string :code
      t.string :name
      t.integer :cardset_id
      t.string :colour
      t.string :rarity
      t.string :cost
      t.string :supertype
      t.string :type
      t.string :subtype
      t.text :rulestext
      t.text :flavourtext
      t.integer :power
      t.integer :toughness
      t.string :image
      t.boolean :active

      t.timestamps
    end
  end

  def self.down
    drop_table :cards
  end
end
