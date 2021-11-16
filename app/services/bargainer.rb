# frozen_string_literal: true

class Bargainer
  def call(market:, member:, volume_range:, price_deviation:, max_spread:)
    Rails.logger.info do
      {
        message: 'Market trade creating is started',
        market_symbol: market.symbol,
        member_id: member.id,
        volume_range: volume_range,
        price_deviation: price_deviation,
        service: 'bargainer'
      }
    end

    cancel_member_orders(member, market)
    service = ::OrderServices::CreateOrder.new(member: member)
    volume = Random.rand(volume_range)
    volume = market.round_amount(volume.to_d)
    price = average_price(market, price_deviation, max_spread)
    if price.nil?
      if Rails.env.sandbox?
        price = market.trades.last.price
      else
        Rails.logger.info { { message: 'No price to bargain. Cancel process', service: 'bargainer' } }
        return
      end
    end

    sides = %w[buy sell].shuffle
    sides.each do |side|
      result = service.perform(market: market, side: side, ord_type: 'limit', volume: volume, price: price)
      if result.successful?
        Rails.logger.info { { message: 'Order is created', market_symbol: market.symbol, order_id: result.data.id, service: 'bargainer' } }
      else
        Rails.logger.error { { message: 'Order creating is failed', side: side, error_message: result.errors.first, market_symbol: market.symbol, service: 'bargainer' } }
      end
    end
    sleep 0.03
    cancel_member_orders(member, market)

    Rails.logger.info { { message: 'Market trade creating is finished', market_symbol: market.symbol, member_id: member.id, volume: volume, price: price, service: 'bargainer' } }
  end

  private

  def average_price(market, price_deviation, max_spread)
    order_ask_price = OrderAsk.top_price(market.symbol)
    order_bid_price = OrderBid.top_price(market.symbol)
    if order_ask_price.nil? || order_bid_price.nil?
      Rails.logger.warn { { message: "Can't calculate price", order_ask_price: order_ask_price, order_bid_price: order_bid_price, market_symbol: market.symbol, service: 'bargainer' } }
      return nil
    end
    if (order_ask_price - order_bid_price) / (order_ask_price + order_bid_price) > max_spread
      Rails.logger.warn { { message: 'Order book spread is too wide', order_ask_price: order_ask_price, order_bid_price: order_bid_price, market_symbol: market.symbol, service: 'bargainer' } }
      return nil
    end

    price = (order_ask_price + order_bid_price) / 2
    price *= 1 + Random.rand(-price_deviation..price_deviation)
    price = market.round_price(price)
    if price >= order_ask_price || price <= order_bid_price
      Rails.logger.warn { { message: 'Order book spread is too narrow', order_ask_price: order_ask_price, order_bid_price: order_bid_price, market_symbol: market.symbol, service: 'bargainer' } }
      return nil
    end

    price
  end

  def cancel_member_orders(member, market)
    member
      .orders
      .with_state(:wait, :pending)
      .where(market_type: ::Market::DEFAULT_TYPE, market: market.symbol)
      .where(canceling_at: nil)
      .find_each do |order|
      Rails.logger.info { { message: 'Cancel order', order_id: order.id, current_state: order.state, service: 'bargainer' } }
      order.trigger_cancellation
    end
  end
end
