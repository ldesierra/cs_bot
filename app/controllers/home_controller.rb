class HomeController < ApplicationController
  def index
    if user_signed_in?
      @portfolio = current_user.portfolio || current_user.create_portfolio
      @transactions = @portfolio.transactions.includes(:item).order(created_at: :desc)
    end
  end
end
