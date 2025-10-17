class TargetsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_target, only: [:show, :edit, :update, :destroy]

  def index
    @targets = current_user.snipes.where(to_bid: false).order(created_at: :desc)
  end

  def show
  end

  def new
    @target = current_user.snipes.build
  end

  def create
    @target = current_user.snipes.build(target_params)
    @target.to_bid = false # Ensure to_bid is set to false for targets

    if @target.save
      redirect_to targets_path, notice: 'Target was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @target.update(target_params)
      redirect_to targets_path, notice: 'Target was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @target.destroy
    redirect_to targets_path, notice: 'Target was successfully deleted.'
  end

  private

  def set_target
    @target = current_user.snipes.find(params[:id])
  end

  def target_params
    params.require(:snipe).permit(:name_to_seek, :max_price, :min_float, :max_float)
  end
end
