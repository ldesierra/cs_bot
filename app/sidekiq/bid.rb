require 'httparty'
require 'telegram/bot'

class Bid
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def initialize(item_id, amount)
    @item_id = item_id
    @amount = amount
    @next_buyer_for_this_call = next_buyer
  end

  def call
    bid_response = bid(@item_id, @amount)
    $next_buyer = (buyer == "2" ? "0" : (buyer.to_i + 1).to_s)

    if bid_response["success"]
      $bidded_by[@item_id] = buyer
      send_telegram_message_new_bidder(@item_id, buyer)
    elsif bid_response.dig("message_localized", "key") == "insufficient_balance"
      send_telegram_message_failed(@item_id, buyer, $next_buyer)
      $bidded_by[@item_id] = $next_buyer
    else
      send_telegram_message_failed_other(@item_id, buyer)
    end

    return bid_response
  end

  private

  def buyer
    $bidded_by ||= {}
    $bidded_by.keys.include?(@item_id) ? $bidded_by[@item_id] : @next_buyer_for_this_call
  end

  def next_buyer
    $next_buyer || ENV["next_buyer"].to_s
  end

  def buyer_key
    case buyer
    when "0"
      ENV["api_key"]
    when "1"
      ENV["api_key_bro"]
    when "2"
      ENV["api_key_agus"]
    end
  end

  def bid(item_id, amount)
    HTTParty.post(
      "https://csgoempire.com/api/v2/trading/deposit/#{item_id}/bid",
      headers: {
        "Authorization" => "Bearer #{buyer_key}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      body: { bid_value: amount }.to_json
    )
  end

  def send_telegram_message_new_bidder(item_id, buyer)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: "New bidder for item #{item_id} is #{buyer}")
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: "New bidder for item #{item_id} is #{buyer}")
    end
  end

  def send_telegram_message_failed(item_id, buyer, next_buyer)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: "Failed to bid for item #{item_id} by #{buyer} going to #{next_buyer}")
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: "Failed to bid for item #{item_id} by #{buyer} now going to #{next_buyer}")
    end
  end

  def send_telegram_message_failed_other(item_id, buyer)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: "Failed to bid for item #{item_id} by #{buyer}")
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: "Failed to bid for item #{item_id} by #{buyer}")
    end
  end
end
