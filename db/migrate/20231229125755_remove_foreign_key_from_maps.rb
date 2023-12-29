class RemoveForeignKeyFromMaps < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :maps, column: :user_id
  end
end
