# frozen_string_literal: true

class Bargainer
  def call(market:, member:, volume:)
    Rails.logger.debug { { message: 'Market trade creating is started', market_symbol: market.symbol, member_id: member.id, volume: volume, service: 'bargainer' } }

    service = ::OrderServices::CreateOrder.new(member: member)
    price = average_price(market)
    if price.nil?
      cancel_member_orders(member, market)
      return
    end

    sides = %w[buy sell].shuffle
    sides.each do |side|
      result = service.perform(market: market, side: side, ord_type: 'limit', volume: volume, price: price)
      Rails.logger.error { { message: 'Order creating is failed', side: side, error_message: result.errors.first, market_symbol: market.symbol, service: 'bargainer' } } if result.failed?
    end
    cancel_member_orders(member, market)

    Rails.logger.debug { { message: 'Market trade creating is finished', market_symbol: market.symbol, member_id: member.id, volume: volume, service: 'bargainer' } }
  end

  private

  def average_price(market)
    order_ask_price = OrderAsk.top_price(market.symbol)
    order_bid_price = OrderBid.top_price(market.symbol)
    if order_ask_price.nil? || order_bid_price.nil?
      Rails.logger.warn { { message: "Can't calculate price", order_ask_price: order_ask_price, order_bid_price: order_bid_price, market_symbol: market.symbol, service: 'bargainer' } }
      return nil
    end

    price = market.round_price((order_ask_price + order_bid_price) / 2)
    if price == order_ask_price || price == order_bid_price
      Rails.logger.warn { { message: 'Order book spread is too narrow', order_ask_price: order_ask_price, order_bid_price: order_bid_price, market_symbol: market.symbol, service: 'bargainer' } }
      return nil
    end

    price
  end

  def cancel_member_orders(member, market)
    orders = member.orders.with_state(:wait, :pending).where(market_type: ::Market::DEFAULT_TYPE, market: market.symbol)
    orders.each(&:trigger_cancellation)
  end
end
