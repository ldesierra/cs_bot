require 'httparty'
require 'telegram/bot'

class BidJobKeychain
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]

  def perform(item)
    begin
      message = item_message(item)
      send_telegram_message(message) if message.present?

      if (good_expensive(item) && item["purchase_price"] < 60000) || (item["above_recommended_price"] < 0 && item["purchase_price"] < 6000)
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      end
    rescue StandardError => e
      send_telegram_message("Error: #{e.message}")
    end
  end

  private

  def good_expensive(item)
    names = ["Hot Howl", "Hot Wurst", "Baby Karat T", "Baby Karat CT", "Diamond Dog", "Semi-Precious", 
    "Glitter Bomb", "8 Ball IGL", "Lil' Ferno", "Butane Buddy",   #drboom
     "Lil' Boo", "Quick Silver", "Lil' Eldritch", "Lil' Serpent"]  #missing link com

    return false unless names.any? { |name| item["keychains"].present? && item["keychains"].first["name"]&.include?(name) }
    (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 10
  end

  def bid_for(item)
    response = bid(item, item["purchase_price"])

    if response["success"]
      return "Bid placed for #{item["market_name"]} with id #{item["id"]} amount #{item["purchase_price"].to_f / 162.8}."
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
    "#{ENV["next_buyer"].to_s == "0" ? "LUCAS" : "MATEO"} KEYCHAIN SKIN FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: message)
    end
  end
end
