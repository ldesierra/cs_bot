require 'httparty'
require 'telegram/bot'

class Bid
  def initialize(item, amount)
    @item = item
    @amount = amount
    @next_buyer_for_this_call = next_buyer
  end

  def call
    bid_response = bid(@item, @amount)
    $next_buyer = (buyer == "2" ? "0" : (buyer.to_i + 1).to_s)

    if bid_response["success"]
      $bidded_by[@item] = buyer
    elsif bid_response.dig("message_localized", "key") == "insufficient_balance"
      $bidded_by[@item] = $next_buyer
    end

    return bid_response
  end

  private

  def buyer
    $bidded_by ||= {}
    $bidded_by.keys.include?(@item) ? $bidded_by[@item] : @next_buyer_for_this_call
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

  def bid(item, amount)
    HTTParty.post(
      "https://csgoempire.com/api/v2/trading/deposit/#{item}/bid",
      headers: {
        "Authorization" => "Bearer #{buyer_key}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      },
      body: { bid_value: amount }.to_json
    )
  end
end
