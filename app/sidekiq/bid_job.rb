require 'httparty'
require 'telegram/bot'

class BidJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def perform(item, amount)
    puts "BidJob"
    if item["market_value"].to_f > 1600
      message = item_message(item)
    elsif item["wear"].to_f <= 0.000
      message = item_message(item)
      other_message = bid_for(:special, item, amount)
    else
      message = item_message(item)
      other_message = bid_for(:normal, item, amount)
    end

    send_telegram_message(message) if message.present?
    send_telegram_message(other_message) if other_message.present?
  end

  private

  def bid_for(kind, item, amount)
    if (item["purchase_price"].to_f / 160) < (kind == :special ? 10 : 1)
      response = bid(item, (amount || item["purchase_price"]))

      if response["success"]
        ends_at = Time.at(response["auction_data"]["auction_ends_at"])
        seconds_left = (ends_at - Time.now).to_i
        seconds_left = seconds_left - 15
        seconds_left = seconds_left < 0 ? 0 : seconds_left
        BidJob.perform_in(seconds_left.seconds, item, nil)
        return "Bid placed for #{item["market_name"]} (special wear ≤ 0.000). Ends in #{seconds_left} seconds."
      else
        if response["message_localized"].include?("offer_already_placed")
          response = bid_for(kind, item, response["data"]["next_bid"])
        else
          return "Failed to bid on special item #{item["market_name"]}. Error: #{response["message"]}"
        end
      end
    end
  end

  def bid(item, amount)
    if amount > 1600
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
    "Bid for #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
  end
end
