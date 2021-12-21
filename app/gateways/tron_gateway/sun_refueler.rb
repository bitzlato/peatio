# frozen_string_literal: true

class TronGateway
  module SunRefueler
    def refuel_sun!(target_address)
      target_address = target_address.address if target_address.is_a? PaymentAddress

      required_amount = required_sun_balance_to_collect(target_address)
      target_balance  = fetch_balance(target_address)

      if required_amount < target_balance
        logger.info('Target balance is enought')
        return
      end

      from_address = hot_wallet.address
      to_address = target_address
      private_key = hot_wallet.blockchain_address.private_key.private_hex

      tx = create_coin_transaction!(from_address: from_address, to_address: to_address,
                                    amount: required_amount.base_units, private_key: private_key)

      tx.options.merge! required_amount: required_amount
      tx
    end
    alias refuel_gas! refuel_sun!
  end
end
