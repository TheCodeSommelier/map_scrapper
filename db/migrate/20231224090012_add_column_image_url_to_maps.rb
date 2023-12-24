class AddColumnImageUrlToMaps < ActiveRecord::Migration[7.1]
  def change
    add_column :maps, :image_url, :string
  end
end
