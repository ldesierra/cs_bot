require 'httparty'
require 'telegram/bot'

class BidJobGloves
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def perform(item)
    message = item_message(item)
    send_telegram_message(message) if message.present?

    if item["market_name"].include?("Vice") && item["wear"] < 0.20 && item["above_recommended_price"] < 15
      other_message = bid_for(item)
      send_telegram_message(other_message) if other_message.present?
    elsif (item["above_recommended_price"] < 7 && item["wear"] < 0.18) || (item["above_recommended_price"] < 3)
      other_message = bid_for(item)
      send_telegram_message(other_message) if other_message.present?
    end
  end

  private

  def bid_for(item)
    response = bid(item, item["purchase_price"])

    if response["success"]
      return "Bid placed for #{item["market_name"]} with id #{item["id"]} amount #{item["purchase_price"].to_f / 160}."
    else
      return "Failed to bid on item #{item["market_name"]}. Error: #{response["message"]}"
    end
  end

  def bid(item, amount)
    api_key = ENV["next_buyer"].to_s == "0" ? ENV["api_key"] : ENV["api_key_bro"]

    HTTParty.post(
      "https://csgoempire.com/api/v2/trading/deposit/#{item["id"]}/bid",
      headers: {
        "Authorization" => "Bearer #{api_key}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      body: { bid_value: amount }.to_json
    )
  end

  def item_message(item)
    "ITEM FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
  end
end
