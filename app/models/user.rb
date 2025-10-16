class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :portfolio, dependent: :destroy

  def total_profit
    return off_skin_balance unless portfolio&.transactions&.any?

    portfolio.transactions
             .where.not(sell: nil).pluck(:sell, :buy_price).sum { |sell, buy_price| sell - buy_price }
  end
end
