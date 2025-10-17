require 'httparty'

class SearchItemsController < ApplicationController
  before_action :authenticate_user!

  def index; end

  def fade
    begin
      not_finished = true
      items = []
      page = 1

      while not_finished
        response = call_empire_api(page, "fade")
        if response.code == 200
          if response["data"].empty?
            not_finished = false
          else
            page = page + 1
            items << response["data"]
          end
        else
          @error = "Error fetching items: #{response.code}"
          @fade_items = []
        end
      end

      @fade_items = get_fade_items(items.flatten)
    rescue StandardError => e
      @error = "Error: #{e.message}"
      @fade_items = []
    end
  end

  def low_float
    begin
      # Get current page from params, default to 1
      @current_page = params[:page]&.to_i || 1

      # Call Empire API with the current page
      response = call_empire_api(@current_page)

      if response.code == 200
        all_items = response["data"]
        @low_float_items = get_low_float_items(all_items)

        # Simple pagination variables
        @items_per_page = 2000
        @total_items = response["total"] || (@low_float_items.length * 10) # Fallback estimation
        @total_pages = (@total_items.to_f / @items_per_page).ceil
        @has_prev = @current_page > 1
        @has_next = @current_page < @total_pages
        @prev_page = @current_page - 1 if @has_prev
        @next_page = @current_page + 1 if @has_next
      else
        @error = "Error fetching items: #{response.code}"
        @low_float_items = []
        @current_page = 1
        @total_pages = 1
        @has_prev = false
        @has_next = false
      end
    rescue StandardError => e
      @error = "Error: #{e.message}"
      @low_float_items = []
      @current_page = 1
      @total_pages = 1
      @has_prev = false
      @has_next = false
    end
  end

  def gloves
    begin
      not_finished = true
      items = []
      page = 1

      while not_finished
        response = call_empire_api(page, "Gloves")
        if response.code == 200
          if response["data"].empty?
            not_finished = false
          else
            page = page + 1
            items << response["data"]
          end
        else
          @error = "Error fetching items: #{response.code}"
          @glove_items = []
        end
      end

      @glove_items = get_gloves(items.flatten)
    rescue StandardError => e
      @error = "Error: #{e.message}"
      @glove_items = []
    end
  end

  def keychain
    begin
      # Get current page from params, default to 1
      @current_page = params[:page]&.to_i || 1

      # Call Empire API with the current page
      response = call_empire_api(@current_page)

      if response.code == 200
        all_items = response["data"]
        @keychain_items = get_keychains(all_items)

        # Simple pagination variables
        @items_per_page = 2000
        @total_items = response["total"] || (@keychain_items.length * 10) # Fallback estimation
        @total_pages = (@total_items.to_f / @items_per_page).ceil
        @has_prev = @current_page > 1
        @has_next = @current_page < @total_pages
        @prev_page = @current_page - 1 if @has_prev
        @next_page = @current_page + 1 if @has_next
      else
        @error = "Error fetching items: #{response.code}"
        @keychain_items = []
        @current_page = 1
        @total_pages = 1
        @has_prev = false
        @has_next = false
      end
    rescue StandardError => e
      @error = "Error: #{e.message}"
      @keychain_items = []
      @current_page = 1
      @total_pages = 1
      @has_prev = false
      @has_next = false
    end
  end

  def blue_gem
    begin
      not_finished = true
      items = []
      page = 1

      while not_finished
        response = call_empire_api(page, "Case Hardened")
        if response.code == 200
          if response["data"].empty?
            not_finished = false
          else
            page = page + 1
            items << response["data"]
          end
        else
          @error = "Error fetching items: #{response.code}"
          @blue_gem_items = []
        end
      end

      @blue_gem_items = get_blue_gem_items(items.flatten)
    rescue StandardError => e
      @error = "Error: #{e.message}"
      @blue_gem_items = []
    end
  end

  def mark_item_as_viewed
    Rails.logger.info "mark_item_as_viewed called with params: #{params.inspect}"
    Rails.logger.info "Current user: #{current_user&.id}"

    item_id = params[:item_id]
    Rails.logger.info "Item ID: #{item_id}"

    if item_id.present?
      begin
        # Log current state before marking
        Rails.logger.info "User #{current_user.id} current seen_item_ids: #{current_user.seen_item_ids.inspect}"

        current_user.mark_item_as_seen(item_id)

        # Verify the change was persisted
        current_user.reload
        Rails.logger.info "User #{current_user.id} seen_item_ids after marking: #{current_user.seen_item_ids.inspect}"
        Rails.logger.info "Item #{item_id} is now seen: #{current_user.has_seen_item?(item_id)}"

        respond_to do |format|
          format.json { render json: { status: 'success', viewed: true, seen_items_count: current_user.seen_item_ids.length } }
          format.html { redirect_back(fallback_location: root_path, notice: 'Item marked as viewed!') }
        end
      rescue => e
        Rails.logger.error "Error in mark_item_as_seen: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        respond_to do |format|
          format.json { render json: { status: 'error', message: 'Database error' }, status: :internal_server_error }
          format.html { redirect_back(fallback_location: root_path, alert: 'Database error') }
        end
      end
    else
      Rails.logger.error "Item ID is blank"
      respond_to do |format|
        format.json { render json: { status: 'error', message: 'Item ID required' }, status: :bad_request }
        format.html { redirect_back(fallback_location: root_path, alert: 'Item ID required') }
      end
    end
  rescue => e
    Rails.logger.error "Error marking item as viewed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.json { render json: { status: 'error', message: 'Failed to mark as viewed' }, status: :internal_server_error }
      format.html { redirect_back(fallback_location: root_path, alert: 'Failed to mark as viewed') }
    end
  end

  private

  def good_usd_50_keychain
    ["Hot Wurst", "Hot Howl", "Baby Karat CT", "Baby Karat T", "8 Ball IGL", "Lil' Ferno", "Butane Buddy", "Glitter Bomb", "Lil' Serpent", "Lil' Eldritch", "Lil' Boo", "Quick Silver"]
  end

  def good_usd_20_keychain
    ["Semi-Precious", "Lil' Monster", "Diamond Dog"]
  end

  def good_other_keychain
    ["Die-cast AK", "Lil' Squirt", "Titeenium AWP", "Semi-Precious", "Baby Karat CT", "Baby Karat T", "Diner Dog", "Lil' Monster", "Diamond Dog", "Hot Wurst", "Hot Howl", "Lil' Chirp", "Piñatita", "Lil' Happy", "Lil' Prick", "Lil' Hero", "Lil' Boo", "Quick Silver", "Lil' Eldritch", "Lil' Serpent", "Lil' Eco", "Eye of Ball", "Lil' Yeti", "Hungry Eyes", "Flash Bomb", "Glitter Bomb", "8 Ball IGL", "Lil' Ferno", "Butane Buddy"]
  end

  def good_usd_50_keychain?(item)
    return false unless good_usd_50_keychain.any? { |name| item["keychains"].first["name"]&.include?(name) }

    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 30)
  end

  def good_usd_20_keychain?(item)
    return false unless good_usd_20_keychain.any? { |name| item["keychains"].first["name"]&.include?(name) }

    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 10)
  end

  def good_other_keychain?(item)
    return false unless good_other_keychain.any? { |name| item["keychains"].first["name"]&.include?(name) }
    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 5)
  end

  def call_empire_api(page, search_term = "")
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=#{page}#{search_term.present? ? "&search=#{search_term}" : ""}&auction=no",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end

  def get_blue_gem_items(items)
    items.filter { |item| item["blue_percentage"].present? && item["blue_percentage"].to_f >= 50 }
  end

  def get_keychains(items)
    items.filter { |item| !item["market_name"].include?("Charm") && item["keychains"].present? && item["keychains"].first["name"].present? }
         .filter { |item| good_usd_50_keychain?(item) || good_usd_20_keychain?(item) || good_other_keychain?(item) }
  end

  def get_gloves(items)
    items.filter { |item| good_field_tested_gloves(item) || good_minimal_gloves(item) }
  end

  def good_field_tested_gloves(item)
    return false unless item["wear"].present?

    (item["wear"] > 0.15 && item["wear"] < 0.19)
  end

  def good_minimal_gloves(item)
    return false unless item["wear"].present?

    (item["wear"] > 0.07 && item["wear"] < 0.085)
  end

  def get_fade_items(items)
    items.filter { |item| item["fade_percentage"].present? && item["fade_percentage"].to_f >= 95 }
         .filter { |item| item["market_name"].include?("Factory") }
  end

  def get_low_float_items(items)
    items.filter { |item| item["wear"].present? && item["wear"].to_f <= 0.001 }
  end
end
