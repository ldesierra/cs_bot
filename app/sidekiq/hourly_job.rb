require 'httparty'
require 'telegram/bot'

class HourlyJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]
  TELEGRAM_CHAT_ID_BRO = ENV["TELEGRAM_CHAT_ID_BRO"]
  TELEGRAM_CHAT_ID_AGUS = ENV["TELEGRAM_CHAT_ID_AGUS"]
  USD_50_KEYCHAINS = ["Hot Wurst", "Hot Howl", "Baby Karat CT", "Baby Karat T", "8 Ball IGL", "Lil' Ferno", "Butane Buddy", "Glitter Bomb", "Lil' Serpent", "Lil' Eldritch", "Lil' Boo", "Quick Silver"]
  USD_20_KEYCHAINS = ["Semi-Precious", "Lil' Monster", "Diamond Dog"]
  KEYCHAIN_NAMES = ["Die-cast AK", "Lil' Squirt", "Titeenium AWP", "Semi-Precious", "Baby Karat CT", "Baby Karat T", "Diner Dog", "Lil' Monster", "Diamond Dog", "Hot Wurst", "Hot Howl", "Lil' Chirp", "Piñatita", "Lil' Happy", "Lil' Prick", "Lil' Hero", "Lil' Boo", "Quick Silver", "Lil' Eldritch", "Lil' Serpent", "Lil' Eco", "Eye of Ball", "Lil' Yeti", "Hungry Eyes", "Flash Bomb", "Glitter Bomb", "8 Ball IGL", "Lil' Ferno", "Butane Buddy"]

  def perform
    page = 1
    not_finished = true
    messages = []

    while not_finished &&
      response = call_empire_api(page)
      if response.code == 200
        if response["data"].empty?
          not_finished = false
        else
          low_floats = get_low_float_items(response)
          nice_fade_items = get_nice_fade_items(response)
          blue_gem_items = get_blue_gem_items(response)
          good_keychain = get_good_keychain(response)
          good_keychain_50 = get_good_keychain_50(response)
          good_keychain_20 = get_good_keychain_20(response)
          nice_gloves_items = get_nice_gloves_items(response)
          nice_gloves_items_mw = get_nice_gloves_items_mw(response)

          if low_floats.any?
            messages << "found low float: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]} with price #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if good_keychain.any?
            messages << "found good keychain: #{good_keychain.map { |item| "#{item["market_name"]} - #{item["id"]} (charm: #{ item["keychains"]&.dig(0, "name") }) and weapon price: #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if good_keychain_50.any?
            messages << "found good keychain 50: #{good_keychain_50.map { |item| "#{item["market_name"]} - #{item["id"]} (charm: #{ item["keychains"]&.dig(0, "name") }) and weapon price: #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if good_keychain_20.any?
            messages << "found good keychain 20: #{good_keychain_20.map { |item| "#{item["market_name"]} - #{item["id"]} (charm: #{ item["keychains"]&.dig(0, "name") }) and weapon price: #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if nice_fade_items.any?
            messages << "found nice fade: #{nice_fade_items.map { |item| "#{item["market_name"]} - #{item["id"]} with fade percentage #{ item["fade_percentage"] } and above price #{ item["above_recommended_price"] } with price #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if blue_gem_items.any?
            messages << "found blue gem: #{blue_gem_items.map { |item| "#{item["market_name"]} - #{item["id"]} with blue percentage #{ item["blue_percentage"] } and above price #{ item["above_recommended_price"] } with price #{ item["purchase_price"].to_f / 162.8 }" }.join(', ')}"
          end
          if nice_gloves_items.any?
            messages << "found nice gloves: #{nice_gloves_items.map { |item| "#{item["market_name"]} - #{item["id"]} with above price #{ item["above_recommended_price"] } with price #{ item["purchase_price"].to_f / 162.8 } with wear #{item["wear"]}" }.join(', ')} }"
          end
          if nice_gloves_items_mw.any?
            messages << "found nice gloves: #{nice_gloves_items_mw.map { |item| "#{item["market_name"]} - #{item["id"]} with above price #{ item["above_recommended_price"] } with price #{ item["purchase_price"].to_f / 162.8 } with wear #{item["wear"]}" }.join(', ')} }"
          end
        end
      end

      page = page + 1
    end

    messages.each do |message|
      send_telegram_message(message)
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

  def get_good_keychain_50(response)
    response["data"].filter { |item| !item["market_name"]&.include?("Charm") }
                    &.filter { |item| item["keychains"].present? }
                    &.filter { |item| good_usd_50_keychain(item)}
  end

  def get_good_keychain_20(response)
    response["data"].filter { |item| !item["market_name"]&.include?("Charm") }
                    &.filter { |item| item["keychains"].present? }
                    &.filter { |item| good_usd_20_keychain(item)}
  end

  def get_good_keychain(response)
    response["data"].filter { |item| !item["market_name"]&.include?("Charm") }
                    &.filter { |item| item["keychains"].present? }
                    &.filter { |item| good_other_keychain(item)}
  end

  def get_nice_gloves_items(response)
    names = ["Specialist Gloves | Crimson Web", "Specialist Gloves | Marble Fade", "Hand Wraps | Slaughter", "Hand Wraps | Cobalt Skulls", "Driver Gloves | Imperial Plaid", "Driver Gloves | King Snake", "Sport Gloves | Nocts", "Specialist Gloves | Tiger Strike", "Driver Gloves | Snow Leopard"]
    items = response["data"].filter { |item| names.any? { |name| item["market_name"].include?(name) } }
                            .filter { |item| item["wear"].to_f >= 0.151 && item["wear"].to_f <= 0.25 }
                            .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }

    items.filter { |item| good_omega(item) || good_slingshot(item) || good_marble_fade(item) || good_tiger_strike(item) || good_amphibious(item) || good_king_snake(item) || good_imperial_plaid(item) || good_vices(item) || good_nocts(item) || good_snow_leopards(item) || good_general_gloves(item) }
  end

  def get_nice_gloves_items_mw(response)
    names = ["Specialist Gloves | Marble Fade", "Sport Gloves | Omega", "Sport Gloves | Slingshot", "Sport Gloves | Amphibious", "Hand Wraps | Cobalt Skulls", "Driver Gloves | Imperial Plaid", "Driver Gloves | King Snake", "Sport Gloves | Nocts", "Specialist Gloves | Tiger Strike", "Sport Gloves | Vice", "Driver Gloves | Snow Leopard"]
    items = response["data"].filter { |item| names.any? { |name| item["market_name"].include?(name) } }
                            .filter { |item| item["wear"].to_f >= 0.071 && item["wear"].to_f <= 0.1 }
                            .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }

    items.filter { |item| good_omega(item) || good_slingshot(item) || good_marble_fade(item) || good_tiger_strike(item) || good_amphibious(item) || good_king_snake(item) || good_imperial_plaid(item) || good_vices(item) || good_nocts(item) || good_snow_leopards(item) || good_general_gloves(item) }
  end

  def good_omega(item)
    return false unless item["market_name"].include?("Sport Gloves | Omega")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 40) || (item["wear"] < 0.21 && item["above_recommended_price"] < 20) || (item["above_recommended_price"] < 10)
  end

  def good_slingshot(item)
    return false unless item["market_name"].include?("Sport Gloves | Slingshot")
    (item["wear"] < 0.18 && item["above_recommended_price"] < 60) || (item["wear"] < 0.21 && item["above_recommended_price"] < 20) || (item["above_recommended_price"] < 10)
  end

  def good_general_gloves(item)
    (item["above_recommended_price"] < 7 && item["wear"] < 0.18) || (item["above_recommended_price"] < 3)
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

  def get_katowice_2014_items(response)
    response["data"].filter { |item| item["stickers"]&.pluck("name")&.any? {|s| s&.include?("(Holo) | Katowice 2014") } }
                    .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }
  end

  def get_nice_fade_items(response)
    items = response["data"].filter { |item| item["fade_percentage"] && item["fade_percentage"].to_f >= 95 }
                            .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }

    items.filter { |item| good_m4_fade(item) || good_awp_fade(item) || good_paracord_fade(item) || good_talon_fade(item) || good_shit_fade(item) || good_fade(item) }

  end

  def good_m4_fade(item)
    return false unless item["market_name"].include?("M4A1-S")

    (item["fade_percentage"].to_f >= 99.8 && item["above_recommended_price"] < 30) || (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 95 && item["above_recommended_price"] < 1)
  end

  def good_awp_fade(item)
    return false unless item["market_name"].include?("AWP")
    (item["fade_percentage"].to_f >= 99.8 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 98.3 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 2)
  end

  def good_paracord_fade(item)
    return false unless item["market_name"].include?("Paracord")
    (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 6) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 0.5)
  end

  def good_talon_fade(item)
    return false unless item["market_name"].include?("Talon")
    (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 20) || (item["fade_percentage"].to_f >= 97.5 && item["above_recommended_price"] < 7) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 2)
  end

  def good_shit_fade(item)
    return false unless item["market_name"].include?("Gut") || item["market_name"].include?("Navaja") || item["market_name"].include?("Flip")
    (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 7) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 4) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 0)
  end

  def good_fade(item)
    (item["fade_percentage"].to_f >= 99 && item["above_recommended_price"] < 10) || (item["fade_percentage"].to_f >= 98 && item["above_recommended_price"] < 6) || (item["fade_percentage"].to_f >= 96 && item["above_recommended_price"] < 0)
  end

  def get_blue_gem_items(response)
    response["data"].filter { |item| item["blue_percentage"] && item["blue_percentage"].to_f >= 50 }
                    .filter { |item| item["above_recommended_price"] < 20 }
                    .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }
  end

  def get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.000 }
                    .filter { |item| item["above_recommended_price"] < 20 }
                    .filter { |item| item["id"].to_s.starts_with?(ENV["start_with"].to_s) || item["id"].to_s.starts_with?("331") }
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

  def call_empire_api(page)
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=#{page}&auction=no",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end
end
