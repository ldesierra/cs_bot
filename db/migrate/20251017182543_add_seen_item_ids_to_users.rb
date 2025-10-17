class AddSeenItemIdsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :seen_item_ids, :json, default: []
  end
end
