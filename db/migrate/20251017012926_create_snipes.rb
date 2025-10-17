class CreateSnipes < ActiveRecord::Migration[7.2]
  def change
    create_table :snipes do |t|
      t.string :name_to_seek
      t.decimal :max_price, precision: 10, scale: 2
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
