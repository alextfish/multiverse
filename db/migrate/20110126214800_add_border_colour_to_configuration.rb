class AddBorderColourToConfiguration < ActiveRecord::Migration
  def self.up
    add_column :configurations, :border_colour, :string
  end

  def self.down
    remove_column :configurations, :border_colour
  end
end
