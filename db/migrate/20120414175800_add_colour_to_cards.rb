class AddColourToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :colour, :string
  end
end
