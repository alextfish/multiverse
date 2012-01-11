class AddLasteditlogsAndNewslists < ActiveRecord::Migration
  def self.up
    create_table :last_edit_logs do |t|
      t.integer :cardset_id
      t.datetime :datestamp
      t.integer :kind 
      t.integer :user_id
      t.integer :object_id
      t.text :text

      t.timestamps
    end
    add_index :last_edit_logs, :cardset_id
    add_index :last_edit_logs, :datestamp
	
    create_table :news_lists do |t|
      t.integer :cardset_id
      t.datetime :datestamp
      t.string :log_ids, :null => false, :default => ''

      t.timestamps
    end
    add_index :news_lists, :cardset_id
	
    add_column :cardsets, :last_edit_log_id, :integer
  end

  def self.down
    remove_column :cardsets, :last_edit_log_id
	
    drop_table :last_edit_logs
    drop_table :news_lists
  end
end
