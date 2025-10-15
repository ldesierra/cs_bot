require 'httparty'
require 'telegram/bot'

class BidJobFade
  include Sidekiq::Job

  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def perform(item, special = false)
    begin
      message = item_message(item)
      send_telegram_message(message) if message.present?

      should_bid = if special
                    if item["market_name"].include?("AWP")
                      (item["fade_percentage"].to_f >= 99.8 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 98.3 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 2)
                    else
                      (item["fade_percentage"].to_f >= 99.8 && item["above_recommended_price"] < 30) || (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 95 && item["above_recommended_price"] < 1)
                    end
                  else
                    if item["market_name"].include?("Paracord")
                      (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 6) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 0.5)
                    elsif item["market_name"].include?("Talon")
                      (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 97.5 && item["above_recommended_price"] < 7) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 2)
                    elsif item["market_name"].include?("Gut") || item["market_name"].include?("Navaja") || item["market_name"].include?("Flip")
                      (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 7) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 4) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 0)
                    else
                      (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 2) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < -5)
                    end
                  end

      if should_bid
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
