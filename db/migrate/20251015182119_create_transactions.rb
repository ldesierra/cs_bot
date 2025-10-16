class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.references :portfolio, null: false, foreign_key: { to_table: :portfolios }
      t.integer :buy_price
      t.integer :sell

      t.timestamps
    end
  end
end
