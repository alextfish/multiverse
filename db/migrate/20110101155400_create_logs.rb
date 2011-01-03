class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.integer :cardset_id
      t.datetime :datestamp
      t.integer :kind 
      t.integer :user_id
      t.integer :object_id
      t.text :text

      t.timestamps
    end
    add_index :logs, :cardset_id
    add_index :logs, :datestamp
  end

  def self.down
    drop_table :logs
  end
end
