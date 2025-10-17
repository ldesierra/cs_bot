class CreateViewedItems < ActiveRecord::Migration[7.2]
  def change
    create_table :viewed_items do |t|
      t.references :user, null: false, foreign_key: true
      t.string :item_id, null: false
      t.timestamps
    end

    add_index :viewed_items, [:user_id, :item_id], unique: true
    add_index :viewed_items, :item_id
  end
end
