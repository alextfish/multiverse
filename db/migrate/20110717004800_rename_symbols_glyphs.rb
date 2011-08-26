class RenameSymbolsGlyphs < ActiveRecord::Migration
  def self.up
    create_table :glyphs do |t|
      t.string :string 
      t.integer :cardset_id
      t.string :url
      t.text :description

      t.timestamps
    end
    add_index :glyphs, :cardset_id
    drop_table :symbols
  end

  def self.down
    create_table :symbols do |t|
      t.string :string 
      t.integer :cardset_id
      t.string :url
      t.text :description

      t.timestamps
    end
    add_index :symbols, :cardset_id
    drop_table :glyphs
  end
end
