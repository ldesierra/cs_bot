require 'httparty'
require 'telegram/bot'

class ApiChecker
  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def self.fetch_messages(all_messages)
    messages = actual_call
    if messages.is_a?(Array)
      new_all_messages = all_messages + messages
      if new_all_messages - all_messages != []
        send_telegram_message((new_all_messages - all_messages).join('\n'))
      end
      all_messages = new_all_messages
    end

    all_messages
  end

  def self.fetch_and_wait
    all_messages = []

    all_messages = fetch_messages(all_messages)
    sleep 20

    all_messages = fetch_messages(all_messages)
    sleep 20

    all_messages = fetch_messages(all_messages)
    sleep 20
  end

  def self.call
    fetch_and_wait
    sleep 20
    fetch_and_wait
    sleep 20
    fetch_and_wait
    sleep 20
    fetch_and_wait
    sleep 20
    fetch_and_wait
    sleep 20
    fetch_and_wait
    sleep 20
    fetch_and_wait
  end

  def self.actual_call
    messages = []
    response = call_empire_api

    if response.code == 200
      katowice_2015_items = get_katowice_2015_items(response)
      katowice_2014_items = get_katowice_2014_items(response)
      low_floats = get_low_float_items(response)

      if katowice_2015_items.any?
        messages << "Katowice 2015 items found: #{katowice_2015_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      elsif low_floats.any?
        messages << "Low floats found: #{low_floats.map { |item| "#{item["market_name"]} with id #{item["id"]}" }.join(', ')}"
      elsif katowice_2014_items.any?
        messages << "Katowice 2014 items found: #{katowice_2014_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      end

      messages
    else
      puts "Error: #{response.code}"
    end
  end

  def self.get_katowice_2015_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2015") } }
  end

  def self.get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2014") } }
  end

  def self.get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.001 }
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
