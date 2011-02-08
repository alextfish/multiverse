class AddMoreIndicesToLogs < ActiveRecord::Migration
  def self.up
    add_index :logs, :kind
    add_index :logs, :object_id
  end

  def self.down
    remove_index :logs, :kind
    remove_index :logs, :object_id
  end
end
