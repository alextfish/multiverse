class AddSingletonStore < ActiveRecord::Migration
  def self.up
	create_table :global_states do |t|
	  t.integer  :singletonguard
	  t.datetime :lastedit
	  t.timestamps
	end
	add_index(:global_states, :singletonguard, :unique => true)
  end
  
  def self.down
    drop_table :global_states
  end
end
