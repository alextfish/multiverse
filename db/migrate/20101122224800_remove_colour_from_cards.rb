class RemoveColourFromCards < ActiveRecord::Migration
  def self.up
    remove_column :cards, :colour
  end

  def self.down
    add_column :cards, :colour, :string
  end
end
