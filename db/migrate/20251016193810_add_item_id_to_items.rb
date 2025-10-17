class AddItemIdToItems < ActiveRecord::Migration[7.2]
  def change
    add_column :items, :item_id, :string
  end
end
