class AddImagesToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :art_url, :string
    add_column :cards, :artist, :string
    add_column :cards, :image_url, :string
  end

  def self.down
    remove_column :cards, :art_url
    remove_column :cards, :artist
    remove_column :cards, :image_url
  end
end
