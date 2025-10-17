class ChangeTransactionPricesToFloat < ActiveRecord::Migration[7.2]
  def change
    change_column :transactions, :buy_price, :float
    change_column :transactions, :sell, :float
  end
end
