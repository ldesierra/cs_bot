require 'httparty'
require 'telegram/bot'

class BidJobBlueGem
  include Sidekiq::Job

  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def perform(item)
    begin
      return unless item["market_name"].include?("Case Hardened")
      message = item_message(item)
      send_telegram_message(message) if message.present?

      if item["blue_percentage"].to_f >= 80 && item["above_recommended_price"] < 20
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      elsif item["blue_percentage"].to_f >= 60 && item["above_recommended_price"] < 10
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      end
    rescue StandardError => e
      send_telegram_message("Error: #{e.message}")
    end
  end

  private

  def bid_for(item)
    response = bid(item, item["purchase_price"])

    if response["success"]
      bidder = $bidded_by[item["id"]]
      bidder = "AGUS" if bidder == "2"
      bidder = "LUCAS" if bidder == "0"
      bidder = "MATEO" if bidder == "1"

      return "Bid placed for #{item["market_name"]} by #{bidder} with id #{item["id"]} amount #{item["purchase_price"].to_f / 162.8}."
    else
      return "Failed to bid on item #{item["market_name"]}. Error: #{response["message"]}"
    end
  end

  def bid(item, amount)
    Bid.new(item["id"], amount).call
  end

  def item_message(item)
    "#{ENV["next_buyer"].to_s == "0" ? "LUCAS" : "MATEO CHUPAVERGA"} FADE FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]} Y FADE #{item["fade_percentage"]}"
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: message)
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_AGUS, text: message)
    end
  end
end
