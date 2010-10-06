class FixTypeColumnName < ActiveRecord::Migration

 def self.up
    rename_column :cards, :type, :cardtype
  end

  def self.down
  end
end
