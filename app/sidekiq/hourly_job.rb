require 'httparty'
require 'telegram/bot'

class HourlyJob
  include Sidekiq::Job

  API_URL = 'https://your-endpoint-x.com'
  TELEGRAM_TOKEN = ENV["TELEGRAM_BOT_TOKEN"]
  TELEGRAM_CHAT_ID = ENV["TELEGRAM_CHAT_ID"]

  def perform
    puts "HourlyJob"

    page = 1
    not_finished = true

    while not_finished
      messages = []

      response = call_empire_api(page)
      if response.code == 200
        if response["data"].empty?
          not_finished = false
        else
          low_floats = get_low_float_items(response)

          if low_floats.any?
            messages << "found: #{low_floats.map { |item| "#{item["market_name"]} - #{item["id"]}" }.join(', ')}"
          end
        end
      end

      page = page + 1
    end
  end

  private

  def get_low_float_items(response)
    response["data"].filter { |item| item["wear"] && item["wear"] <= 0.001 }
  end

  def send_telegram_message(message)
    Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
      bot.api.send_message(chat_id: TELEGRAM_CHAT_ID, text: message)
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
