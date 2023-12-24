class ChangePriceColumnDataType < ActiveRecord::Migration[7.1]
  def change
    change_column :maps, :price, :string
  end
end
