class CreateDetailsPages < ActiveRecord::Migration
  def self.up
    create_table :details_pages do |t|
      t.integer :cardset_id
      t.string :title
      t.text :body

      t.timestamps
    end
    add_index :details_pages, :cardset_id
  end

  def self.down
    drop_table :details_pages
  end
end
