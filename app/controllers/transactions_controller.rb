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

    Rails.logger.info "Updating transaction #{@transaction.id} with params: #{transaction_params.inspect}"

    ActiveRecord::Base.transaction do
      if @transaction.update(transaction_params)
        Rails.logger.info "Transaction #{@transaction.id} updated successfully. Sell: #{@transaction.sell}, Buy: #{@transaction.buy_price}"
        # Update user balance when transaction is updated
        redirect_to root_path, notice: 'Transaction updated successfully!'
      else
        Rails.logger.error "Transaction update failed: #{@transaction.errors.full_messages}"
        render :edit, status: :unprocessable_entity
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Transaction not found: #{params[:id]}"
    redirect_to root_path, alert: 'Transaction not found.'
  rescue => e
    Rails.logger.error "Error updating transaction: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    redirect_to root_path, alert: 'An error occurred while updating the transaction. Please try again.'
  end

  private

  def set_portfolio
    @portfolio = current_user.portfolio || current_user.create_portfolio
  end

  def transaction_params
    params.require(:transaction).permit(:buy_price, :sell, item_attributes: [:name, :float, :fade, :blue, :stickers])
  end
end
