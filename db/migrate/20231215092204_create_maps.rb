class CreateMaps < ActiveRecord::Migration[7.1]
  def change
    create_table :maps do |t|
      t.string :title
      t.integer :price
      t.string :map_show_page_link
      t.boolean :bought
      t.string :collection
      t.string :map_maker
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
