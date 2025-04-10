require 'httparty'
require 'telegram/bot'

class ApiChecker2
  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def self.call
    messages = []

    response = call_empire_api(1)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    response = call_empire_api(2)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    response = call_empire_api(4)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    response = call_empire_api(5)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    response = call_empire_api(6)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    response = call_empire_api(7)
    if response.code == 200
      high_floats = get_high_float_items(response)
      low_floats = get_low_float_items(response)

      if low_floats.any?
        messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      elsif high_floats.any?
        messages << "found: #{high_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
      end
    end

    messages
  end

  def self.get_low_float_items(response)
    items = response["data"].filter { |item| item["wear"] && item["wear"] <= 0.000 }
    # items.filter { |item| item["above_recommended_price"] < 200 || item["purchase_price"] < 2000 }
  end

  def self.get_high_float_items(response)
    items = response["data"].filter { |item| item["wear"].present? && item["wear"] == 0.999 }
    # items.filter { |item| item["above_recommended_price"] < 100 || item["purchase_price"] < 2000 }
  end

  def self.call_empire_api(page)
    HTTParty.get("https://csgoempire.com/api/v2/trading/items?per_page=2000&page=#{page}&auction=no",
      headers: {
        "accept" => "application/json",
        "Authorization" => "Bearer #{ENV["api_key"]}"
      }
    )
  end
end
