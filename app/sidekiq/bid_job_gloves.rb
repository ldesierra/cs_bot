require 'httparty'
require 'telegram/bot'

class BidJobGloves
  include Sidekiq::Job

  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def perform(item)
    begin
      message = item_message(item)
      send_telegram_message(message) if message.present?

      if good_vices(item) || good_omega(item) || good_snow_leopards(item) || good_slingshot(item) || good_marble_fade(item) || good_nocts(item) || good_tiger_strike(item) || good_imperial_plaid(item) || good_amphibious(item) || good_king_snake(item)
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      elsif (item["above_recommended_price"] < 7 && item["wear"] < 0.18) || (item["above_recommended_price"] < 3 && item["wear"] < 0.20)
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      end
    rescue StandardError => e
      send_telegram_message("Error: #{e.message}")
    end
  end

  private

  def good_omega(item)
    return false unless item["market_name"].include?("Sport Gloves | Omega")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 40) || (item["wear"] < 0.21 && item["above_recommended_price"] < 20) || (item["above_recommended_price"] < 10)
  end

  def good_slingshot(item)
    return false unless item["market_name"].include?("Sport Gloves | Slingshot")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 60) || (item["wear"] < 0.21 && item["above_recommended_price"] < 20) || (item["above_recommended_price"] < 10)
  end

  def good_tiger_strike(item)
    return false unless item["market_name"].include?("Specialist Gloves | Tiger Strike")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 20) || (item["wear"] < 0.21 && item["above_recommended_price"] < 10) || (item["above_recommended_price"] < 3)
  end

  def good_amphibious(item)
    return false unless item["market_name"].include?("Sport Gloves | Amphibious")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 30) || (item["wear"] < 0.21 && item["above_recommended_price"] < 20) || (item["above_recommended_price"] < 10)
  end

  def good_marble_fade(item)
    return false unless item["market_name"].include?("Specialist Gloves | Marble Fade")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 20) || (item["wear"] < 0.21 && item["above_recommended_price"] < 10) || (item["above_recommended_price"] < 3)
  end

  def good_king_snake(item)
    return false unless item["market_name"].include?("Driver Gloves | King Snake")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 70) || (item["wear"] < 0.21 && item["above_recommended_price"] < 15) || (item["above_recommended_price"] < 7)
  end

  def good_imperial_plaid(item)
    return false unless item["market_name"].include?("Driver Gloves | Imperial Plaid")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 25) || (item["wear"] < 0.21 && item["above_recommended_price"] < 14) || (item["above_recommended_price"] < 10)
  end

  def good_vices(item)
    return false unless item["market_name"].include?("Vice")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 90) || item["wear"] < 0.21 && item["above_recommended_price"] < 40 || (item["above_recommended_price"] < 15)
  end

  def good_nocts(item)
    return false unless item["market_name"].include?("Sport Gloves | Nocts")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 10) || (item["wear"] < 0.21 && item["above_recommended_price"] < 5) || (item["above_recommended_price"] < 1)
  end

  def good_snow_leopards(item)
    return false unless item["market_name"].include?("Driver Gloves | Snow Leopard")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 27) || (item["wear"] < 0.21 && item["above_recommended_price"] < 18) || (item["above_recommended_price"] < 10)
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
    Bid.new(item["id"], amount).call
  end

  def item_message(item)
    "#{ENV["next_buyer"].to_s == "0" ? "LUCAS" : "MATEO IMBECIL"} GLOVES FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
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
