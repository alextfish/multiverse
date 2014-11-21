class AddUserToCards < ActiveRecord::Migration
  def self.up
    unless column_exists? :cards, :user_id
      add_column :cards, :user_id, :integer
      add_index :cards, :user_id
    end
  end

  def self.down
    remove_column :cards, :user_id
    remove_index :cards, :user_id
  end
end
