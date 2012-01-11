class AddColourIndicators < ActiveRecord::Migration
  def self.up
    add_column :cards, :colour_indicator, :boolean
  end

  def self.down
    remove_column :cards, :colour_indicator
  end
end
