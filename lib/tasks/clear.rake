# encoding: UTF-8
# frozen_string_literal: true

namespace :clear do
  desc 'Clear database from accounting information.'
  task accounting: :environment do
    table_names = %w[accounts adjustments assets beneficiaries deposits expenses
      liabilities orders payment_addresses revenues trades transfers triggers withdraws]
    table_names.each { |name| ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{name}") }
  end

  desc 'Clear deposits, withdraws, orders, trades, disable markets for currencies associated with given market'
  task :market, [:market_symbol, :batch_limit] => [:environment] do |_, args|
    batch_limit = args[:batch_limit] || 100
    market = ::Market.find_spot_by_symbol(args[:market_symbol])
    currencies = %i(base_unit quote_unit).map do |unit_side|
      market.send(unit_side)
    end
    associated_markets = currencies.map do |currency_id|
      Market.spot.where(
        'base_unit = ? OR quote_unit = ?',
        currency_id,
        currency_id
      )
    end.flatten.uniq

    if (
      extra_associated_markets = associated_markets - [market]
    ).present?
      raise SecurityError.new(
        "The following markets associated with given currencies found:\n\n\t" +
        extra_associated_markets.map{|m| m.as_json.slice("id", "symbol")}.pretty_inspect +
        "\nAborting task!\n" +
        "Please consider implementing additional task to remove multiple markets.\n" +
        "SQL requests to fetch the mentioned markets reads as follows:\n\n" +
        extra_associated_markets.map do |m|
          Market \
          .where(id: m.id) \
          .limit(1) \
          .explain \
          .split(/^.*QUERY PLAN/) \
          .first
        end.join("\n") +
        "\n\nTask aborted!\n\n"
      )
    end

    loop_entity_paginated = lambda do |before_action_message, entity, &block|
      Kernel.puts before_action_message

      while (
        records = entity.limit batch_limit
      ).present?
        Kernel.print "."
        block.call(records)
        sleep 0.01
      end

      Kernel.print "\n... finished\n"
    end

    market.state = "disabled"
    market.save!

    loop_entity_paginated.call(
      "Cancelling open orders for the market #{market.id} ...",
      Order.active.with_market(market)
    ){|orders| orders.each(&:cancel) }

    loop_entity_paginated.call(
      "Dropping trades for the market #{market.id} ...",
      Trade.with_market(market).joins(
        "INNER JOIN orders o " +
        "ON trades.maker_order_id = o.id " +
        "OR trades.taker_order_id = o.id"
      )
    ){|trades| trades.delete_all}

    loop_entity_paginated.call(
      "Dropping orders for the market #{market.id} ...",
      Order.with_market(market)
    ){|orders| orders.delete_all}

    [Deposit, Withdraw, Adjustment, Beneficiary, InternalTransfer, Transaction, Operations::Revenue, Operations::Expense, Operations::Liability, Operations::Asset].each do |model_class|
      loop_entity_paginated.call(
        "Dropping #{model_class} for the currencies #{currencies} ...",
        model_class.where(currency_id: currencies)
      ){|records| records.delete_all}
    end
  end
end
