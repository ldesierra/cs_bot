class SnipesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_snipe, only: [:show, :edit, :update, :destroy]

  def index
    @snipes = current_user.snipes.where(to_bid: true).order(created_at: :desc)
  end

  def show
  end

  def new
    @snipe = current_user.snipes.build
  end

  def create
    @snipe = current_user.snipes.build(snipe_params)
    @snipe.to_bid = true # Ensure to_bid is set to true for snipes

    if @snipe.save
      redirect_to snipes_path, notice: 'Snipe was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @snipe.update(snipe_params)
      redirect_to snipes_path, notice: 'Snipe was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @snipe.destroy
    redirect_to snipes_path, notice: 'Snipe was successfully deleted.'
  end

  private

  def set_snipe
    @snipe = current_user.snipes.find(params[:id])
  end

  def snipe_params
    params.require(:snipe).permit(:name_to_seek, :max_price, :min_float, :max_float, :to_bid)
  end
end
