require 'httparty'
require 'telegram/bot'

class BidJobKeychain
  include Sidekiq::Job

  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_TOKEN_2 = ENV["TELEGRAM_BOT_TOKEN_2"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]
  USD_50_KEYCHAINS = ["Hot Wurst", "Hot Howl", "Baby Karat CT", "Baby Karat T", "8 Ball IGL", "Lil' Ferno", "Butane Buddy", "Glitter Bomb", "Lil' Serpent", "Lil' Eldritch", "Lil' Boo", "Quick Silver"]
  USD_20_KEYCHAINS = ["Semi-Precious", "Lil' Monster", "Diamond Dog"]
  KEYCHAIN_NAMES = ["Die-cast AK", "Lil' Squirt", "Titeenium AWP", "Semi-Precious", "Baby Karat CT", "Baby Karat T", "Diner Dog", "Lil' Monster", "Diamond Dog", "Hot Wurst", "Hot Howl", "Lil' Chirp", "Piñatita", "Lil' Happy", "Lil' Prick", "Lil' Hero", "Lil' Boo", "Quick Silver", "Lil' Eldritch", "Lil' Serpent", "Lil' Eco", "Eye of Ball", "Lil' Yeti", "Hungry Eyes", "Flash Bomb", "Glitter Bomb", "8 Ball IGL", "Lil' Ferno", "Butane Buddy"]

  def perform(item)
    begin
      message = item_message(item)
      send_telegram_message(message) if message.present?

      if (good_usd_50_keychain(item) && item["purchase_price"] < 48000) || (good_usd_20_keychain(item) && item["purchase_price"] < 16000) || (good_other_keychain(item) && item["purchase_price"] > 1600)
        other_message = bid_for(item)
        send_telegram_message(other_message) if other_message.present?
      end
    rescue StandardError => e
      send_telegram_message("Error: #{e.message}")
    end
  end

  private

  def good_usd_50_keychain(item)
    return false unless USD_50_KEYCHAINS.any? { |name| item["keychains"].first["name"]&.include?(name) }

    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 30)
  end

  def good_usd_20_keychain(item)
    return false unless USD_20_KEYCHAINS.any? { |name| item["keychains"].first["name"]&.include?(name) }

    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 10)
  end

  def good_other_keychain(item)
    return false unless KEYCHAIN_NAMES.any? { |name| item["keychains"].first["name"]&.include?(name) }
    (item["purchase_price"].present? && item["suggested_price"].present? && (item["purchase_price"] - item["suggested_price"]).to_f / 162.8 < 5)
  end

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
    "#{ENV["next_buyer"].to_s == "0" ? "LUCAS" : "MATEO"} KEYCHAIN SKIN FOUND #{item["market_name"]} with ID #{item["id"]} — Market: #{item["market_value"]}, Purchase: #{item["purchase_price"]}, Wear: #{item["wear"]}"
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
