class HourlySentsController < ApplicationController
  before_action :authenticate_user!

  def index
    @hourly_sents = HourlySent.includes(:item, :users).order(created_at: :desc)

    # Handle search functionality
    if params[:search].present?
      @hourly_sents = @hourly_sents.joins(:item).where("items.name ILIKE ?", "%#{params[:search]}%")
      @search_query = params[:search]
    end
  end

  def mark_as_viewed
    @hourly_sent = HourlySent.find(params[:id])

    Rails.logger.info "Marking hourly_sent #{@hourly_sent.id} as viewed by user #{current_user.id}"

    ActiveRecord::Base.transaction do
      # Check if user has already viewed this hourly_sent
      unless @hourly_sent.users.include?(current_user)
        @hourly_sent.users << current_user
        Rails.logger.info "Successfully marked hourly_sent #{@hourly_sent.id} as viewed by user #{current_user.id}"
        respond_to do |format|
          format.html { redirect_to "#{hourly_sents_path}#hourly-sent-#{@hourly_sent.id}", notice: 'Marked as viewed!' }
          format.json { render json: { status: 'success', viewed: true } }
        end
      else
        Rails.logger.info "User #{current_user.id} has already viewed hourly_sent #{@hourly_sent.id}"
        respond_to do |format|
          format.html { redirect_to "#{hourly_sents_path}#hourly-sent-#{@hourly_sent.id}", notice: 'Already marked as viewed!' }
          format.json { render json: { status: 'success', viewed: true, message: 'Already viewed' } }
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "Hourly sent not found: #{params[:id]}"
    respond_to do |format|
      format.html { redirect_to hourly_sents_path, alert: 'Hourly sent not found.' }
      format.json { render json: { status: 'error', message: 'Not found' }, status: :not_found }
    end
  rescue => e
    Rails.logger.error "Error marking hourly as viewed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.html { redirect_to hourly_sents_path, alert: 'An error occurred. Please try again.' }
      format.json { render json: { status: 'error', message: 'Server error' }, status: :internal_server_error }
    end
  end
end
