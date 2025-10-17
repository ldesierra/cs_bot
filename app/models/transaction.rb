class Transaction < ApplicationRecord
  belongs_to :portfolio
  has_one :item, class_name: 'Item', foreign_key: 'transaction_involved_id', dependent: :destroy

  accepts_nested_attributes_for :item

  after_update :update_user_balance, if: :saved_change_to_sell?

  def update_user_balance
    portfolio.user.update(balance: (portfolio.user.balance + (sell - buy_price)).to_f)
  end
end
