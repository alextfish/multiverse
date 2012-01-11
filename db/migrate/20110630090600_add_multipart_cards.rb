class AddMultipartCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :multipart, :integer
    add_column :cards, :link_id, :integer
  end

  def self.down
    remove_column :cards, :multipart
    remove_column :cards, :link_id
  end
end
