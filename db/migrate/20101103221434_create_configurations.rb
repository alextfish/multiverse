class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.string :frame
      t.boolean :use_highlighting
      t.boolean :use_addressing
      t.string :default_comment_state
      t.boolean :cardlist_show_comments
      t.boolean :cardlist_show_code
      t.boolean :cardlist_show_active
      t.boolean :card_show_code
      t.boolean :card_show_active
      t.string :visibility
      t.string :commentability

      t.timestamps
    end
  end

  def self.down
    drop_table :configurations
  end
end
