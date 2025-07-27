require 'httparty'
require 'telegram/bot'

class BidJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def perform(item, amount)
    if amount.present?
      bid_for(:wtf, item, false)
    elsif item["purchase_price"].to_f > 1600
      message = item_message(item)

      if item["above_recommended_price"] < 10 && item["purchase_price"].to_f < 6000
        other_message = bid_for(:normal, item, true)
      end
    elsif item["wear"].to_f <= 0.000
      message = item_message(item)
      other_message = bid_for(:special, item, false)
    else
      message = item_message(item)
      other_message = bid_for(:normal, item, false)
    end

    send_telegram_message(message) if message.present?
    send_telegram_message(other_message) if other_message.present?
  end

  private

  def bid_for(kind, item, special)
    if kind == :wtf && (item["purchase_price"].to_f / 160) < 1000
      response = bid(item, item["purchase_price"], true)

      if response["success"]
        return "Bid placed for #{item["market_name"]} with id #{item["id"]} amount #{item["purchase_price"].to_f / 160}."
      else
        return "Failed to bid on #{kind} item #{item["market_name"]}. Error: #{response["message"]}"
      end
    end

    if special || (item["purchase_price"].to_f / 160) < (kind == :special ? 4 : 0.5)
      response = bid(item, item["purchase_price"], special)

      if response["success"]
        return "Bid placed for #{item["market_name"]} with id #{item["id"]} amount #{item["purchase_price"].to_f / 160}."
      else
        return "Failed to bid on #{kind} item #{item["market_name"]}. Error: #{response["message"]}"
      end
    end
  end

  def bid(item, amount, special)
    if amount > 1600 && !special
      return
    end

    HTTParty.post(
      "https://csgoempire.com/api/v2/trading/deposit/#{item["id"]}/bid",
      headers: {
        "Authorization" => "Bearer #{ENV["api_key"]}",
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
