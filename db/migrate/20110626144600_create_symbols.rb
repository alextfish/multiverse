class CreateSymbols < ActiveRecord::Migration
  def self.up
    create_table :symbols do |t|
      t.string :string 
      t.integer :cardset_id
      t.string :url
      t.text :description

      t.timestamps
    end
    add_index :symbols, :cardset_id
  end

  def self.down
    drop_table :symbols
  end
end
