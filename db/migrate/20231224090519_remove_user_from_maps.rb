class RemoveUserFromMaps < ActiveRecord::Migration[7.1]
  def change
    remove_reference :maps, :user, null: false, foreign_key: true
  end
end
