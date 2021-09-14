if defined? MoneyRails
  MoneyRails.configure do |config|
    config.default_bank = nil
    config.amount_column = { postfix: '_cents', type: :integer, null: false, limit: 8, default: 0, present: true }

    # default
    config.rounding_mode = BigDecimal::ROUND_HALF_EVEN
    config.default_format = {
      no_cents_if_whole: true,
      translate: true,
      drop_trailing_zeros: true
    }
  end
end
