class CreateCardsets < ActiveRecord::Migration
  def self.up
    create_table :cardsets do |t|
      t.string :name
      t.integer :user_id
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :cardsets
  end
end
