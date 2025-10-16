class CreateItems < ActiveRecord::Migration[7.2]
  def change
    create_table :items do |t|
      t.references :transaction_involved, null: false, foreign_key: { to_table: :transactions }
      t.string :name
      t.float :float
      t.float :fade
      t.float :blue
      t.string :stickers

      t.timestamps
    end
  end
end
