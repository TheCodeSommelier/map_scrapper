class RemoveCollectionFromMaps < ActiveRecord::Migration[7.1]
  def change
    remove_column :maps, :collection, :string
  end
end
