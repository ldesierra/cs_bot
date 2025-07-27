require 'httparty'
require 'telegram/bot'

class HourlyJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def perform
    page = 1
    not_finished = true
    messages = []

    while not_finished &&
      response = call_empire_api(page)
      if response.code == 200
        if response["data"].empty?
          not_finished = false
        else
          low_floats = get_low_float_items(response)
          katowice_2014_items = get_katowice_2014_items(response)
          nice_fade_items = get_nice_fade_items(response)
          blue_gem_items = get_blue_gem_items(response)
          nice_gloves_items = get_nice_gloves_items(response)

          if low_floats.any?
            messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]} with price #{ item["purchase_price"].to_f / 160 }" }.join(', ')}"
          end
          if katowice_2014_items.any?
            messages << "found: #{katowice_2014_items.map { |item| "#{item["market_name"]} - #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") } with price #{ item["purchase_price"].to_f / 160 }" }.join(', ')}"
          end
          if nice_fade_items.any?
            messages << "found: #{nice_fade_items.map { |item| "#{item["market_name"]} - #{item["id"]} with fade percentage #{ item["fade_percentage"] } with price #{ item["purchase_price"].to_f / 160 }" }.join(', ')}"
          end
          if blue_gem_items.any?
            messages << "found: #{blue_gem_items.map { |item| "#{item["market_name"]} - #{item["id"]} with blue percentage #{ item["blue_percentage"] } with price #{ item["purchase_price"].to_f / 160 }" }.join(', ')}"
          end
          if nice_gloves_items.any?
            messages << "found: #{nice_gloves_items.map { |item| "#{item["market_name"]} - #{item["id"]} with price #{ item["purchase_price"].to_f / 160 }" }.join(', ')}"
          end
        end
      end

      page = page + 1
    end

    messages.each do |message|
      send_telegram_message(message)
    end
  end

  private

  def get_nice_gloves_items(response)
    names = ["Specialist Gloves | Crimson Web", "Specialist Gloves | Marble Fade", "Hand Wraps | Slaughter", "Hand Wraps | Cobalt Skulls", "Driver Gloves | Imperial Plaid", "Driver Gloves | King Snake", "Sport Gloves | Nocts", "Specialist Gloves | Tiger Strike", "Driver Gloves | Snow Leopard"]
    response["data"].filter { |item| names.any? { |name| item["market_name"].include?(name) } }
                    .filter { |item| item["wear"].to_f >= 0.151 && item["wear"].to_f <= 0.18 }
                    .filter { |item| item["above_recommended_price"] < 15 }
  end

  def get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("(Holo) | Katowice 2014") } }
  end

  def get_nice_fade_items(response)
    items = response["data"].filter { |item| item["fade_percentage"] && item["fade_percentage"].to_f >= 97 }
    items.filter { |item| item["market_name"].include?("AWP") || item["market_name"].include?("M4A1-S") || item["market_name"].include?("Knife") }
         .filter { |item| item["above_recommended_price"] < 20 }
  end

  def get_blue_gem_items(response)
    response["data"].filter { |item| item["blue_percentage"] && item["blue_percentage"].to_f >= 40 }
                    .filter { |item| item["above_recommended_price"] < 20 }
  end

  def get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.000 }
                    .filter { |item| item["above_recommended_price"] < 15 }
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
  rescue StandardError => e
    Rails.logger.error("Telegram Error: #{e.message}")
  end

  def call_empire_api(page)
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=#{page}&auction=no",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end
end
