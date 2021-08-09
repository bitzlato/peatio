require_relative 'abstract_command'
class EthereumGateway
  class TransactionCreator < AbstractCommand
    DEFAULT_ETH_GAS_LIMIT = 21_000
    DEFAULT_ETH_GAS_PRICE = :standard

    DEFAULT_ERC20_GAS_LIMIT = 90_000
    DEFAULT_ERC20_GAS_PRICE = :standard

    def call(amount:, from_address:, to_address:, secret:, contract_address: nil, subtract_fee: false, gas_limit: nil, gas_price: nil)
      raise 'amount must be a Money' unless amount.is_a? Money
      raise 'not tested'
      txid, amount, gas_price, gas_limit = contract_address.present? ?
        create_erc20_transaction!(amount: amount,
                                  from_address: from_address,
                                  to_address: to_address,
                                  contract_address: contract_address,
                                  secret: secret,
                                  gas_limit: gas_limit || DEFAULT_ETH_GAS_LIMIT,
                                  gas_price: gas_price || DEFAULT_ETH_GAS_PRICE)
      : create_eth_transaction!(amount: amount,
                                from_address: from_address,
                                to_address: to_address,
                                subtract_fee: subtract_fee,
                                secret: secret,
                                gas_limit: gas_limit || DEFAULT_ERC20_GAS_LIMIT,
                                gas_price: gas_price || DEFAULT_ERC20_GAS_PRICE)

      txid = normalize_txid txid
      raise Ethereum::Client::Error, \
        "Withdrawal from #{from_address} to #{to_address} failed." unless valid_txid? txid
      Peatio::Transaction.new(
        from_address: from_address,
        to_address:   to_address,
        currency_id:  amount.currency.id,
        amount:       amount,
        hash:         normalize_addres(txid),
        options: { gas_price: gas_price, gas_limit: gas_limit }
      )
    end

    def create_eth_transaction!(from_address:,
                                to_address:,
                                amount:,
                                secret:,
                                gas_price: DEAFULT_ETH_GAS_PRICE,
                                gas_limit: DEFAULT_ETH_GAS_LIMIT)
      gas_price ||= fetch_gas_price

      amount_base_units = amount.base_units
      # Subtract fees from initial deposit amount in case of deposit collection
      amount_base_units -= gas_limit.to_i * gas_price.to_i if subtract_fee

      txid = client
        .json_rpc(:personal_sendTransaction,
                  [{
          from:     normalize_address(from_address),
          to:       normalize_address(to_address),
          value:    '0x' + amount_base_units.to_s(16),
          gas:      '0x' + gas_limit.to_i.to_s(16),
          gasPrice: '0x' + gas_price.to_i.to_s(16)
        }.compact, secret])

      return txid, Money.new(amount_base_units, amount.currency), gas_price, gas_limit
    end

    def create_erc20_transaction!(from_address:,
                                  to_address:,
                                  amount:,
                                  contract_address:,
                                  secret:,
                                  gas_limit: DEFAULT_ETH_GAS_LIMIT,
                                  gas_price: DEAFULT_ETH_GAS_PRICE)
      data = abi_encode('transfer(address,uint256)',
                        normalize_address(to_address),
                        '0x' + amount.base_units.to_s(16))

      gas_price ||= fetch_gas_price

      txid = client.json_rpc(:personal_sendTransaction,
                             [{
        from:     normalize_address(from_address),
        to:       options.fetch(contract_address_option),
        data:     data,
        gas:      '0x' + gas_limit.to_i.to_s(16),
        gasPrice: '0x' + gas_price.to_i.to_s(16)
      }.compact, secret])
      return txid, amount, gas_price, gas_limit
    end

    private

    # ex calculate_gas_price
    def fetch_gas_price(gas_price)
      gas_price = client.json_rpc(:eth_gasPrice, []).to_i(16)
      Rails.logger.info { "Current gas price #{gas_price}" }
      gas_price
    end
  end
end
