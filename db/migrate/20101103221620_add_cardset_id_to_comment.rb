class AddCardsetIdToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :cardset_id, :integer
  end

  def self.down
    remove_column :comments, :cardset_id
  end
end
