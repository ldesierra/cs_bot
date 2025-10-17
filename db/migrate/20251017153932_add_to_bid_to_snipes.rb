class AddToBidToSnipes < ActiveRecord::Migration[7.2]
  def change
    add_column :snipes, :to_bid, :boolean, default: true, null: false
  end
end
