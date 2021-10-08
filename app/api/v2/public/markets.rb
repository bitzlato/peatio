# frozen_string_literal: true

module API
  module V2
    module Public
      class Markets < Grape::API
        helpers ::API::V2::OrderHelpers
        helpers ::API::V2::ParamHelpers

        OrderBook = Struct.new(:asks, :bids)

        resource :markets do
          desc 'Get all available markets.',
               is_array: true,
               success: API::V2::Entities::Market
          params do
            use :pagination
            optional :ordering,
                     values: { value: %w[asc desc], message: 'public.markets.invalid_ordering' },
                     default: 'asc',
                     desc: 'If set, returned values will be sorted in specific order, defaults to \'asc\'.'
            optional :order_by,
                     values: { value: %w[id position], message: 'public.markets.invalid_order_by' },
                     default: 'position',
                     desc: 'Name of the field, which result will be ordered by.'
            optional :base_unit,
                     type: String,
                     values: { value: ->(v) { ::Currency.exists?(v) },
                               message: 'public.markets.base_unit_doesnt_exist' },
                     desc: 'Strict filter for base unit'
            optional :quote_unit,
                     type: String,
                     values: { value: ->(v) { ::Currency.exists?(v) },
                               message: 'public.markets.quote_unit_doesnt_exist' },
                     desc: 'Strict filter for quote unit'
            optional :type,
                     type: { value: String, message: 'public.market.non_string_market_type' },
                     values: { value: -> { ::Market::TYPES }, message: 'public.market.invalid_market_type' },
                     default: ::Market::DEFAULT_TYPE,
                     desc: 'Strict filter for market type'
            optional :search, type: Hash, default: {} do
              optional :base_code,
                       type: String,
                       desc: 'Search base currency code using LIKE'
              optional :quote_code,
                       type: String,
                       desc: 'Search qoute currency code using LIKE'
              optional :base_name,
                       type: String,
                       desc: 'Search base currency name using LIKE'
              optional :quote_name,
                       type: String,
                       desc: 'Search quote currency name using LIKE'
            end
          end
          get '/' do
            search_params = params[:search]
                            .slice(:base_code, :quote_code, :base_name, :quote_name)
                            .transform_keys { |k| "#{k}_cont" }
                            .merge(m: 'or')

            search = ::Market.active
                             .where(type: params[:type])
                             .where(params.slice(:base_unit, :quote_unit))
                             .ransack(search_params)

            # Add default ordering (position asc) for cases markets where unit position is same.
            search.sorts = ["#{params[:order_by]} #{params[:ordering]}", 'position asc']

            present paginate(Rails.cache.fetch("markets_#{params}", expires_in: 600) { search.result.load.to_a }),
                    with: API::V2::Entities::Market,
                    extended: !params[:extended].nil?
          end

          desc 'Get the order book of specified market.',
               is_array: true,
               success: API::V2::Entities::OrderBook
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.spot.active.pluck(:symbol) }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:symbol] }
            optional :asks_limit,
                     type: { value: Integer, message: 'public.order_book.non_integer_ask_limit' },
                     values: { value: 1..200, message: 'public.order_book.invalid_ask_limit' },
                     default: 20,
                     desc: 'Limit the number of returned sell orders. Default to 20.'
            optional :bids_limit,
                     type: { value: Integer, message: 'public.order_book.non_integer_bid_limit' },
                     values: { value: 1..200, message: 'public.order_book.invalid_bid_limit' },
                     default: 20,
                     desc: 'Limit the number of returned buy orders. Default to 20.'
            optional :exclude_member_id, type: Integer,
                                         desc: 'ID of member to exclude orders from the presented book'
          end

          get ':market/order-book', requirements: { market: /[\w.\-]+/ } do
            asks = OrderAsk.active.with_market(params[:market]).matching_rule.limit(params[:asks_limit])
            bids = OrderBid.active.with_market(params[:market]).matching_rule.limit(params[:bids_limit])
            if params[:exclude_member_id].present?
              asks = asks.where.not(member_id: params[:exclude_member_id])
              bids = bids.where.not(member_id: params[:exclude_member_id])
            end
            book = OrderBook.new asks, bids
            present book, with: API::V2::Entities::OrderBook
          end

          desc 'Get recent trades on market, each trade is included only once. Trades are sorted in reverse creation order.',
               is_array: true,
               success: API::V2::Entities::Trade
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.spot.active.pluck(:symbol) }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:symbol] }
            optional :limit,
                     type: { value: Integer, message: 'public.trade.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.trade.invalid_limit' },
                     default: 100,
                     desc: 'Limit the number of returned trades. Default to 100.'
            optional :timestamp,
                     type: { value: Integer, message: 'public.trade.non_integer_timestamp' },
                     desc: 'An integer represents the seconds elapsed since Unix epoch.'\
                           'If set, only trades executed before the time will be returned.'
            optional :order_by,
                     type: String,
                     values: { value: %w[asc desc], message: 'public.trade.invalid_order_by' },
                     default: 'desc',
                     desc: "If set, returned trades will be sorted in specific order, default to 'desc'."
          end
          get ':market/trades', requirements: { market: /[\w.\-]+/ } do
            options = { order_by: params[:order_by] }
            if params[:timestamp].present?
              if params[:order_by] == 'asc'
                options[:start_time] = params[:timestamp]
              else
                options[:end_time] = params[:timestamp]
              end
            end
            present Trade.public_from_influx(params[:market], params[:limit], options), with: API::V2::Entities::PublicTrade
          end

          desc 'Get depth or specified market. Both asks and bids are sorted from highest price to lowest.'
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.spot.active.pluck(:symbol) }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:symbol] }
            optional :limit,
                     type: { value: Integer, message: 'public.market_depth.non_integer_limit' },
                     values: { value: 1..1000, message: 'public.market_depth.invalid_limit' },
                     default: 300,
                     desc: 'Limit the number of returned price levels. Default to 300.'
          end
          get ':market/depth', requirements: { market: /[\w.\-]+/ } do
            asks = OrderAsk.get_depth(params[:market])[0, params[:limit]]
            bids = OrderBid.get_depth(params[:market])[0, params[:limit]]
            { timestamp: Time.now.to_i, asks: asks, bids: bids }
          end

          desc 'Get OHLC(k line) of specific market.'
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.spot.active.pluck(:symbol) }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:symbol] }
            optional :period,
                     type: { value: Integer, message: 'public.k_line.non_integer_period' },
                     values: { value: KLineService::AVAILABLE_POINT_PERIODS, message: 'public.k_line.invalid_period' },
                     default: 1,
                     desc: "Time period of K line, default to 1. You can choose between #{KLineService::AVAILABLE_POINT_PERIODS.join(', ')}"
            optional :time_from,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_from' },
                     allow_blank: { value: false, c_name: 'k_line' },
                     desc: 'An integer represents the seconds elapsed since Unix epoch. If set, only k-line data after that time will be returned.'
            optional :time_to,
                     type: { value: Integer, message: 'public.k_line.non_integer_time_to' },
                     allow_blank: { value: false, c_name: 'k_line' },
                     desc: 'An integer represents the seconds elapsed since Unix epoch. If set, only k-line data till that time will be returned.'
            optional :limit,
                     type: { value: Integer, message: 'public.k_line.non_integer_limit' },
                     values: { value: KLineService::AVAILABLE_POINT_LIMITS, message: 'public.k_line.invalid_limit' },
                     default: 30,
                     desc: 'Limit the number of returned data points default to 30. Ignored if time_from and time_to are given.'
          end
          get ':market/k-line', requirements: { market: /[\w.\-]+/ } do
            KLineService[params[:market], params[:period]]
              .get_ohlc(params.slice(:limit, :time_from, :time_to).merge(offset: true))
          end

          desc 'Get ticker of all markets (For response doc see /:market/tickers/ response).'
          get '/tickers' do
            Rails.cache.fetch(:markets_tickers, expires_in: 60) do
              ::Market.spot.active.ordered.each_with_object({}) do |m, h|
                h[m.symbol] = format_ticker TickersService[m].ticker
              end
            end
          end

          desc 'Get ticker of specific market.',
               success: API::V2::Entities::Ticker
          params do
            requires :market,
                     type: String,
                     values: { value: -> { ::Market.spot.active.pluck(:symbol) }, message: 'public.market.doesnt_exist' },
                     desc: -> { V2::Entities::Market.documentation[:symbol] }
          end
          get '/:market/tickers/', requirements: { market: /[\w.\-]+/ } do
            present format_ticker(TickersService[params[:market]].ticker),
                    with: API::V2::Entities::Ticker
          end
        end
      end
    end
  end
end
