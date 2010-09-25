class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id
      t.integer :card_id
      t.datetime :posttime
      t.text :comment
      t.integer :status

      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end
