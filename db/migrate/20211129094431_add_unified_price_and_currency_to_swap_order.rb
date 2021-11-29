# frozen_string_literal: true

class AddUnifiedPriceAndCurrencyToSwapOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :swap_orders, :unified_price, :decimal, precision: 32, scale: 16
    add_column :swap_orders, :unified_total_amount, :decimal, precision: 32, scale: 16
    add_column :swap_orders, :unified_unit, :string, index: true

    config = Rails.application.config_for(:swap)
    vwap_time = config[:vwap_time]
    unified_currency = Currency.find_by(config[:unified_currency_code])

    SwapOrder.find_each do |swap_order|
      price_service = CurrencyServices::Price.new(base_currency: swap_order.from_currency, quote_currency: swap_order.unified_currency, vwap_time: vwap_time)
      unified_price = price_service.call
      unified_total_amount = unified_price * volume
      swap_order.update unified_total_amount: unified_total_amount, unified_price: unified_price, unified_currency: unified_currency
    end

    change_column_null(:swap_orders, :unified_price, false)
    change_column_null(:swap_orders, :unified_total_amount, false)
    change_column_null(:swap_orders, :unified_unit, false)
  end
end
