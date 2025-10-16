class OffSkinBalanceController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    # Calculate balance: off_skin_balance + sum of sell prices - sum of buy prices
    total_buys = @user.portfolio&.transactions&.where(sell: nil)&.sum(:buy_price) || 0
    new_balance = params[:off_skin_balance].to_f + total_buys

    if @user.update(off_skin_balance: params[:off_skin_balance], balance: new_balance)
      redirect_to root_path, notice: 'Off-skin balance updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def off_skin_balance_params
    params.permit(:off_skin_balance)
  end
end
