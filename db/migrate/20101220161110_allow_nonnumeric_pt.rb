class AllowNonnumericPt < ActiveRecord::Migration

 def self.up
    change_column :cards, :power, :string 
    change_column :cards, :toughness, :string 
  end

  def self.down
    change_column :cards, :power, :integer
    change_column :cards, :toughness, :integer
  end
end
