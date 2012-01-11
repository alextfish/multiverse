class AddUseridToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :user_id, :integer
    rename_column :comments, :user, :user_name
    rename_column :comments, :comment, :body
  end

  def self.down
    remove_column :comments, :user_id
    rename_column :comments, :user_name, :user
    rename_column :comments, :body, :comment
  end
end
