class EnhanceDecklists < ActiveRecord::Migration
  def self.up
    add_column :decklists, :description, :text
    add_column :deck_cards, :section, :string
    add_column :deck_wizards_cards, :name, :string
  end

  def self.down
    remove_column :decklists, :description
    remove_column :deck_cards, :section
    remove_column :deck_wizards_cards, :name
  end
end
