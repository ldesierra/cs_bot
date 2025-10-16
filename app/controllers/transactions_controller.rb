class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_portfolio

  def new
    @transaction = @portfolio.transactions.build
    @transaction.build_item
  end

  def create
    @transaction = @portfolio.transactions.build(transaction_params)

    # Build the item with the transaction reference
    if @transaction.item
      @transaction.item.transaction_involved = @transaction
    end

    if @transaction.save
      # Update user balance when new transaction is created
      update_user_balance
      redirect_to root_path, notice: 'Transaction created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @transaction = @portfolio.transactions.find(params[:id])
  end

  def update
    @transaction = @portfolio.transactions.find(params[:id])

    if @transaction.update(transaction_params)
      # Update user balance when transaction is updated
      update_user_balance
      redirect_to root_path, notice: 'Transaction updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolio || current_user.create_portfolio
  end

  def transaction_params
    params.require(:transaction).permit(:buy_price, :sell, item_attributes: [:name, :float, :fade, :blue, :stickers])
  end

  def update_user_balance
    # Calculate balance: off_skin_balance + sum of sell prices - sum of buy prices
    total_sells = @portfolio.transactions.where.not(sell: nil).sum(:sell)
    total_buys = @portfolio.transactions.sum(:buy_price)
    new_balance = current_user.off_skin_balance + total_sells - total_buys
    current_user.update(balance: new_balance)
  end
end
