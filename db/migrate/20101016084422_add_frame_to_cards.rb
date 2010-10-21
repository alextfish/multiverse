class AddFrameToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :frame, :string
  end

  def self.down
    remove_column :cards, :frame
  end
end
