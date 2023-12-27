class AddImageUrlToMaps < ActiveRecord::Migration[7.1]
  def change
    change_column :maps, :image_url, :string
  end
end
