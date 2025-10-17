class CreateBiddeds < ActiveRecord::Migration[7.2]
  def change
    create_table :biddeds do |t|
      t.integer :bidded_by, null: false
      t.string :item_id, null: false

      t.timestamps
    end

    add_check_constraint :biddeds, "bidded_by IN (0, 1, 2)", name: "check_bidded_by_values"
  end
end
