class AddSpecificAdmins < ActiveRecord::Migration
  def self.up
    add_column :configurations, :admins, :string
  end

  def self.down
    remove_column :configurations, :admins
  end
end
