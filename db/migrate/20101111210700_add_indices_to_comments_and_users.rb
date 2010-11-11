class AddIndicesToCommentsAndUsers < ActiveRecord::Migration
  def self.up
    add_index :users, :name
    add_index :comments, :user_id
  end

  def self.down
    remove_index :users, :name
    remove_index :comments, :user_id
  end
end
