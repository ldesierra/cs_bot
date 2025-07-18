require 'httparty'
require 'telegram/bot'

class SecondlyJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]

  def perform
    puts "SecondlyJob"
    messages = actual_call
    Rails.logger.info("Fetching messages at #{DateTime.now}")

    return unless messages.present?
    send_telegram_message(messages&.join('\n'))
  end

  private

  def actual_call
    messages = []
    response = call_empire_api

    if response.code == 200
      katowice_2015_items = get_katowice_2015_items(response)
      katowice_2014_items = get_katowice_2014_items(response)
      blue_gem_items = get_blue_gem_items(response)
      nice_fade_items = get_nice_fade_items(response)
      low_floats = get_low_float_items(response)
      high_float_items = get_high_float_items(response)
      special_items = get_special_items(response)

      if katowice_2015_items.any?
        messages << "Katowice 2015 items found: #{katowice_2015_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      elsif blue_gem_items.any?
        messages << "Blue gem items found: #{blue_gem_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with blue percentage #{ item["blue_percentage"] }" }.join(', ')}"
      elsif nice_fade_items.any?
        messages << "Nice fade items found: #{nice_fade_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with fade percentage #{ item["fade_percentage"] }" }.join(', ')}"
      elsif high_float_items.any?
        messages << "High float items found: #{high_float_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with float #{ item["wear"] }" }.join(', ')}"
      elsif low_floats.present? && low_floats.any?
        low_floats.each do |item|
          BidJob.perform_async(item, nil)
        end
      elsif katowice_2014_items.any?
        messages << "Katowice 2014 items found: #{katowice_2014_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      elsif special_items.any?
        messages << "Special items found: #{special_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      end

      messages
    else
      puts "Error: #{response.code}"
    end
  end

  def get_katowice_2015_items(response)
    multiple = response["data"].filter do |item|
      count = item["stickers"]&.pluck("name")&.count {|s| s&.include?("Katowice 2015") }
      count.present? && count >= 3
    end
    holo = response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Holo) | Katowice 2015") } }

    multiple + holo
  end

  def get_super_rare_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("OWER (Holo) | Katowice 2014") } }
  end

  def get_special_items(response)
    s = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Dragon Lore") }
    d = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Gungnir") }
    sd = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Fire Serpent") }
    ds = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("The Prince") }
    sds = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Wild Lotus") }
    dsd = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Gold Arabesque") }
    sdsd = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Howl") }
    sdsds = response["data"].filter { |item| item["market_value"] > 260000 && item["above_recommended_price"] < 0 && item["market_name"].include?("Butterfly Knife | Marble") }

    s + d + sd + ds + sds + dsd + sdsd + sdsds
  end

  def get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2014") } }
  end

  def get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.001 }
  end

  def get_nice_fade_items(response)
    response["data"].filter { |item| item["fade_percentage"] && item["fade_percentage"].to_f >= 97 }
  end

  def get_blue_gem_items(response)
    response["data"].filter { |item| item["blue_percentage"] && item["blue_percentage"].to_f >= 25 }
  end

  def get_high_float_items(response)
    response["data"].filter { |item| item["float"] && item["wear"].to_f >= 0.99 }
  end

  def get_good_float_gloves(response)
    s = response["data"].filter { |item| item["market_name"].include?("Gloves") }
    good_minimal = s.filter { |item| item["wear"].to_f >= 0.07 && item["wear"].to_f <= 0.08 }
    good_field = s.filter { |item| item["wear"].to_f >= 0.15 && item["wear"].to_f <= 0.17 }
    good_minimal + good_field
  end

  def call_empire_api
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=1&auction=yes",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_BRO, text: message)
    end
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID_AGUS, text: message)
    end
  rescue StandardError => e
    Rails.logger.error("Telegram Error: #{e.message}")
  end
end
