class CreateMechanics < ActiveRecord::Migration
  def self.up
    create_table :mechanics do |t|
      t.string :name 
      t.integer :cardset_id
      t.string :codename 
      t.text :reminder 
      t.integer :parameters 
      t.text :description

      t.timestamps
    end
    add_index :mechanics, :cardset_id
  end

  def self.down
    drop_table :mechanics
  end
end
