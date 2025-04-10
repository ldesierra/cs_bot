require 'httparty'
require 'telegram/bot'

class ApiChecker
  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def self.call
    all_messages = []
    messages = actual_call
    new_all_messages = all_messages + messages
    if new_all_messages - all_messages != []
      send_telegram_message((new_all_messages - all_messages).join('\n'))
    end
    all_messages = new_all_messages
    sleep 10

    messages = actual_call
    new_all_messages = all_messages + messages
    if new_all_messages - all_messages != []
      send_telegram_message((new_all_messages - all_messages).join('\n'))
    end
    all_messages = new_all_messages
    sleep 10

    messages = actual_call
    new_all_messages = all_messages + messages
    if new_all_messages - all_messages != []
      send_telegram_message((new_all_messages - all_messages).join('\n'))
    end
    all_messages = new_all_messages
    sleep 10

    messages = actual_call
    new_all_messages = all_messages + messages
    if new_all_messages - all_messages != []
      send_telegram_message((new_all_messages - all_messages).join('\n'))
    end
    all_messages = new_all_messages
    sleep 10

    messages = actual_call
    new_all_messages = all_messages + messages
    if new_all_messages - all_messages != []
      send_telegram_message((new_all_messages - all_messages).join('\n'))
    end
    all_messages = new_all_messages
  end

  def self.actual_call
    puts "Actual call"
    messages = []

    response = call_empire_api
    if response.code == 200
      katowice_2015_items = get_katowice_2015_items(response)
      katowice_2014_items = get_katowice_2014_items(response)
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)
      special_items = get_special_items(response)

      if katowice_2015_items.any?
        messages << "Katowice 2015 items found: #{katowice_2015_items.map { |item| "#{item["market_name"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      elsif low_floats.any?
        messages << "Low floats found: #{low_floats.map { |item| item["market_name"] }.join(', ')}"
      elsif katowice_2014_items.any?
        messages << "Katowice 2014 items found: #{katowice_2014_items.map { |item| "#{item["market_name"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      elsif high_floats.any?
        messages << "High floats found: #{high_floats.map { |item| item["market_name"] }.join(', ')}"
      elsif special_items.any?
        messages << "Special items found: #{special_items.map { |item| item["market_name"] }.join(', ')}"
      end

      messages
    else
      send_telegram_message(response.code)
    end
  end

  def self.get_katowice_2015_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2015") } }
  end

  def self.get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2014") } }
  end

  def self.get_gold_items(response)
    response["data"].filter do |item|
      count = item["stickers"]&.pluck("name")&.count { |s| s&.include?("Gold") }
      count.present? && count > 2 && !item["market_name"].include?("Souvenir")
    end
  end

  def self.get_special_items(response)
    items = ["AK-47 | Case Hardened", "Desert Eagle | Blaze (Factory New)"]
    response["data"].filter { |item| item["market_name"].match? Regexp.union(items) }
  end

  def self.get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.001 }
  end

  def self.get_high_float_items(response)
    response["data"].filter { |item| item["wear"].present? && item["wear"] == 0.999 }
  end

  def self.call_empire_api
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=1&auction=yes",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end

  def self.send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
  rescue StandardError => e
    Rails.logger.error("Telegram Error: #{e.message}")
  end
end
