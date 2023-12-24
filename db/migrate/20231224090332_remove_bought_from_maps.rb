class RemoveBoughtFromMaps < ActiveRecord::Migration[7.1]
  def change
    remove_column :maps, :bought, :boolean
  end
end
