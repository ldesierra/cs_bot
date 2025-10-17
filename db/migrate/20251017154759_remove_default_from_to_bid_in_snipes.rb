class RemoveDefaultFromToBidInSnipes < ActiveRecord::Migration[7.2]
  def change
    change_column_default :snipes, :to_bid, nil
  end
end
