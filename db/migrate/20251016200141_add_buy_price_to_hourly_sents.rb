class AddBuyPriceToHourlySents < ActiveRecord::Migration[7.2]
  def change
    add_column :hourly_sents, :buy_price, :integer
  end
end
