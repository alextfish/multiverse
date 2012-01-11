class AddCardsetComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :cardset_id, :integer
    add_index :comments, :cardset_id
  end

  def self.down
    remove_column :comments, :cardset_id
  end
end
