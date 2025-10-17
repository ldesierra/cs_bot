class HomeController < ApplicationController
  def index
    if user_signed_in?
      @portfolio = current_user.portfolio || current_user.create_portfolio
      @transactions = @portfolio.transactions.includes(:item).order(created_at: :desc)

      # Handle search functionality
      if params[:search].present?
        @transactions = @transactions.joins(:item).where("items.name ILIKE ?", "%#{params[:search]}%")
        @search_query = params[:search]
      end
    end
  end
end
