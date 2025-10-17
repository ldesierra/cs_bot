class BiddedsController < ApplicationController
  def index
    @biddeds = Bidded.includes(:item).order(created_at: :desc)
  end
end

