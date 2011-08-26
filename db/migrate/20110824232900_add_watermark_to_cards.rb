class AddWatermarkToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :watermark, :string
  end

  def self.down
    remove_column :cards, :watermark
  end
end
