class AddCardsetIdToConfiguration < ActiveRecord::Migration
  def self.up
    add_column :configurations, :cardset_id, :integer
  end

  def self.down
    remove_column :configurations, :cardset_id
  end
end
