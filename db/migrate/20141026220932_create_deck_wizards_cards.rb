class CreateDeckWizardsCards < ActiveRecord::Migration
  def change
    create_table :deck_wizards_cards do |t|
      t.integer :gatherer_id
      t.references :decklist, index: true
      t.string :section
      t.integer :count

      t.timestamps
    end
  end
end
