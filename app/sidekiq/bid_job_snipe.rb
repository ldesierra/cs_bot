require 'httparty'
require 'telegram/bot'

class BidJobSnipe
  include Sidekiq::Job

  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def perform(item)
    puts "MARKET NAME: #{item["market_name"]}"
    snipe = Snipe.find_by(name_to_seek: item["market_name"])

    return unless snipe.present?
    message = item_message(item)

    if snipe.to_bid?
      good_in_price = item["purchase_price"].to_f <= (snipe.max_price * 163)
      good_in_wear = item["wear"].present? && item["wear"].to_f >= snipe.min_float && item["wear"].to_f <= snipe.max_float

      if good_in_price && good_in_wear
        other_message = bid_for(item, snipe)
      end

      send_telegram_message(message, snipe) if message.present?
      send_telegram_message(other_message, snipe) if other_message.present?
    else
      good_in_price = item["purchase_price"].to_f <= (snipe.max_price * 163)
      good_in_wear = item["wear"].present? && item["wear"].to_f >= snipe.min_float && item["wear"].to_f <= snipe.max_float

      if good_in_price && good_in_wear
        send_telegram_message(message, snipe) if message.present?
      end
    end
  end

  private

  def bid_for(item, snipe)
    response = bid(item, item["purchase_price"], snipe)

    if response["success"]
      return "Bid placed for #{item["market_name"]} with id #{item["id"]} amount #{item["purchase_price"].to_f / 162.8}."
    else
      return "Failed to bid on item #{item["market_name"]}. Error: #{response["message"]}"
    end
  end

  def api_key(snipe)
    case User.find_by(id: snipe.user_id).user_number
    when "0"
      ENV["api_key"]
    when "1"
      ENV["api_key_bro"]
    when "2"
      ENV["api_key_agus"]
    end
  end

  def telegram_chat_id(snipe)
    case User.find_by(id: snipe.user_id).user_number
    when "0"
      TELEGRAM_CHAT_ID
    when "1"
      TELEGRAM_CHAT_ID_BRO
    when "2"
      TELEGRAM_CHAT_ID_AGUS
    end
  end

  def bid(item, amount, snipe)
    HTTParty.post(
      "https://csgoempire.com/api/v2/trading/deposit/#{item["id"]}/bid",
      headers: {
        "Authorization" => "Bearer #{api_key(snipe)}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      body: { bid_value: amount }.to_json
    )
  end

  def item_message(item)
    "ITEM FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
  end

  def send_telegram_message(message, snipe)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN_2) do |bot|
      bot.api.send_message(chat_id: telegram_chat_id(snipe), text: message)
    end
  end
end
