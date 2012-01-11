class AddMultipleAdmins < ActiveRecord::Migration
  def self.up
    add_column :configurations, :editability, :string
    add_column :configurations, :adminability, :string
    add_column :details_pages, :last_edit_by, :integer
    add_column :cards, :last_edit_by, :integer
    add_column :configurations, :last_edit_by, :integer
    add_column :cardsets, :last_edit_by, :integer
  end

  def self.down
    remove_column :configurations, :editability
    remove_column :configurations, :adminability
    remove_column :details_pages, :last_edit_by
    remove_column :cards, :last_edit_by
    remove_column :configurations, :last_edit_by
    remove_column :cardsets, :last_edit_by
  end
end
