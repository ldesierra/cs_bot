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
    messages = actual_call

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
      m4_and_awp_fade = get_m4_and_awp_fade(response)
      low_floats = get_low_float_items(response)
      high_float_items = get_high_float_items(response)
      nice_gloves_items = get_nice_gloves_items(response)

      puts "TIME IS #{Time.now.hour}"
      puts "MENOR A 5? #{Time.now.hour < 5}"
      puts "MAYOR O IGUAL A 11? #{Time.now.hour >= 11}"

      if blue_gem_items.any?
        messages << "Blue gem items found: #{blue_gem_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with blue percentage #{ item["blue_percentage"] }" }.join(', ')}"
      elsif nice_fade_items.any? && (Time.now.hour < 5 || Time.now.hour >= 11)
        nice_fade_items.each do |item|
          BidJobFade.perform_async(item, false)
        end
      elsif nice_gloves_items.any? && (Time.now.hour < 5 || Time.now.hour >= 11)
        nice_gloves_items.each do |item|
          BidJobGloves.perform_async(item)
        end
      elsif m4_and_awp_fade.any? && (Time.now.hour < 5 || Time.now.hour >= 11)
        m4_and_awp_fade.each do |item|
          BidJobFade.perform_async(item, true)
        end
      elsif low_floats.present? && low_floats.any? && (Time.now.hour < 2 || Time.now.hour >= 8)
        low_floats.each do |item|
          BidJob.perform_async(item, nil)
        end
      elsif katowice_2014_items.any?
        messages << "Katowice 2014 items found: #{katowice_2014_items.map { |item| "#{item["market_name"]} with id #{item["id"]} with stickers #{ item["stickers"]&.pluck("name") }" }.join(', ')}"
      end

      messages
    else
      puts "Error: #{response.code}"
    end
  end

  def get_nice_gloves_items(response)
    names = ["Specialist Gloves | Crimson Web", "Specialist Gloves | Marble Fade", "Sport Gloves | Omega", "Sport Gloves | Slingshot", "Hand Wraps | Slaughter", "Sport Gloves | Amphibious", "Hand Wraps | Cobalt Skulls", "Driver Gloves | Imperial Plaid", "Driver Gloves | King Snake", "Sport Gloves | Nocts", "Specialist Gloves | Tiger Strike", "Sport Gloves | Vice", "Driver Gloves | Snow Leopard"]
    response["data"].filter { |item| names.any? { |name| item["market_name"].include?(name) } }
                    .filter { |item| item["wear"].to_f >= 0.151 && item["wear"].to_f <= 0.20 }
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

  def get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("Katowice 2014") } }
  end

  def get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.001 }
  end

  def get_nice_fade_items(response)
    response["data"].filter { |item| item["fade_percentage"] && item["fade_percentage"].to_f >= 95 }
                    .filter { |item| item["market_name"].include?("Knife") }
  end

  def get_m4_and_awp_fade(response)
    response["data"].filter { |item| item["market_name"].include?("M4A1-S") || item["market_name"].include?("AWP") }
                    .filter { |item| item["fade_percentage"] && item["fade_percentage"].to_f >= 95 }
  end

  def get_blue_gem_items(response)
    response["data"].filter { |item| item["blue_percentage"] && item["blue_percentage"].to_f >= 40 }
  end

  def get_high_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"].to_f >= 0.99 }
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
