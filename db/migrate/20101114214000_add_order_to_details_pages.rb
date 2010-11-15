class AddOrderToDetailsPages < ActiveRecord::Migration
  def self.up
    add_column :details_pages, :order, :integer
  end

  def self.down
    remove_column :details_pages, :order
  end
end
