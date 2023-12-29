class RemoveUserIdFromMaps < ActiveRecord::Migration[7.1]
  def change
    remove_column :maps, :user_id, :bigint
  end
end
