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
  task :market, [:market_symbol] => [:environment] do |_, args|
    market = ::Market.find_spot_by_symbol(args[:market_symbol])
    currencies = %i(base_unit quote_unit).map do |unit_side|
      #Currency.find \
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
        "The following markets associated with given currencies found:\n\t" +
        extra_associated_markets.map{|m| m.symbol}.inspect
      ) 
    end

    loop_entity_paginated = lambda do |before_action_message, entity, &block|
      Kernel.puts before_action_message

      while (
        # limit 100 per sql call according to https://github.com/bitzlato/peatio/issues/7#issuecomment-878195604
        records = entity.limit 100
      ).present?
        Kernel.print "."
        block.call(records)
        sleep 0.01
      end

      Kernel.print "\n... finished\n"
    end

    market.state = "disabled"
    market.save

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

    loop_entity_paginated.call(
      "Dropping deposits for the currencies #{currencies} ...",
      Deposit.where(currency_id: currencies)
    ){|deposits| deposits.delete_all}

    loop_entity_paginated.call(
      "Dropping withdraws for the currencies #{currencies} ...",
      Withdraw.where(currency_id: currencies)
    ){|withdraws| withdraws.delete_all}

    loop_entity_paginated.call(
      "Dropping adjustments for the currencies #{currencies} ...",
      Adjustment.where(currency_id: currencies)
    ){|adjustments| adjustments.delete_all}

    loop_entity_paginated.call(
      "Dropping beneficiaries for the currencies #{currencies} ...",
      Beneficiary.where(currency_id: currencies)
    ){|beneficiaries| beneficiaries.delete_all}

    loop_entity_paginated.call(
      "Dropping internal_transfers for the currencies #{currencies} ...",
      InternalTransfer.where(currency_id: currencies)
    ){|internal_transfers| internal_transfers.delete_all}

    loop_entity_paginated.call(
      "Dropping operations for the currencies #{currencies} ...",
      Operation.where(currency_id: currencies)
    ){|operations| operations.delete_all}

    loop_entity_paginated.call(
      "Dropping transactions for the currencies #{currencies} ...",
      Transaction.where(currency_id: currencies)
    ){|transactions| transactions.delete_all}
  end
end
