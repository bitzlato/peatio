require_relative 'abstract_command'
class EthereumGateway
  class TransactionCreator < AbstractCommand
    DEFAULT_ETH_GAS_LIMIT = Settings.eth.gas_limit
    DEFAULT_ERC20_GAS_LIMIT = Settings.erc20.gas_limit

    # @param amount - in base units (cents)
    def call(amount:,
             from_address:,
             to_address:,
             secret:,
             contract_address: nil,
             subtract_fee: false,
             gas_limit: nil,
             gas_factor: 1)
      raise "amount (#{amount.class}) must be an Integer (base units)" unless amount.is_a? Integer
      raise "can't subtract_fee for erc20 transaction" if subtract_fee && contract_address.present?
      gas_price ||= (fetch_gas_price * gas_factor).to_i

      peatio_transaction = contract_address.present? ?
        create_erc20_transaction!(amount: amount,
                                  from_address: from_address,
                                  to_address: to_address,
                                  contract_address: contract_address,
                                  secret: secret,
                                  gas_limit: gas_limit || DEFAULT_ETH_GAS_LIMIT,
                                  gas_price: gas_price)
      : create_eth_transaction!(amount: amount,
                                from_address: from_address,
                                to_address: to_address,
                                subtract_fee: subtract_fee,
                                secret: secret,
                                gas_limit: gas_limit || DEFAULT_ERC20_GAS_LIMIT,
                                gas_price: gas_price)
      peatio_transaction.options.merge! gas_factor: gas_factor
      peatio_transaction
    end

    def create_eth_transaction!(from_address:,
                                to_address:,
                                amount:,
                                secret:,
                                gas_limit: DEFAULT_ETH_GAS_LIMIT,
                                gas_price:,
                                subtract_fee: false)

      # Subtract fees from initial deposit amount in case of deposit collection
      amount -= gas_limit.to_i * gas_price.to_i if subtract_fee

      txid = validate_txid!(
        client
        .json_rpc(:personal_sendTransaction,
                  [{
          from:     normalize_address(from_address),
          to:       normalize_address(to_address),
          value:    '0x' + amount.to_s(16),
          gas:      '0x' + gas_limit.to_i.to_s(16),
          gasPrice: '0x' + gas_price.to_i.to_s(16)
        }.compact, secret])
      )

      Peatio::Transaction.new(
        from_address: from_address,
        to_address:   to_address,
        amount:       amount,
        hash:         normalize_address(txid),
        options: {
          gas_price: gas_price,
          gas_limit: gas_limit,
          subtract_fee: subtract_fee
        }
      )
    end

    def create_erc20_transaction!(from_address:,
                                  to_address:,
                                  amount:,
                                  contract_address:,
                                  secret:,
                                  gas_limit: DEFAULT_ERC20_GAS_LIMIT,
                                  gas_price:)
      data = abi_encode('transfer(address,uint256)', normalize_address(to_address), '0x' + amount.to_s(16))

      txid = validate_txid!(
        client.json_rpc(:personal_sendTransaction,
                        [{
          from:     normalize_address(from_address),
          to:       contract_address,
          data:     data,
          gas:      '0x' + gas_limit.to_i.to_s(16),
          gasPrice: '0x' + gas_price.to_i.to_s(16)
        }.compact, secret])
      )
      Peatio::Transaction.new(
        from_address: from_address,
        to_address:   to_address,
        amount:       amount,
        hash:         normalize_address(txid),
        options: {
          contract_address: contract_address,
          gas_price: gas_price,
          gas_limit: gas_limit,
        }
      )
    end

    private

    def validate_txid!(txid)
      raise Ethereum::Client::Error, \
        "Transaction from #{from_address} to #{to_address} for #{amount} failed (invalid txid #{txid})." unless valid_txid? txid
      txid
    end

    # ex calculate_gas_price
    def fetch_gas_price
      client.json_rpc(:eth_gasPrice, []).to_i(16).tap do |gas_price|
        Rails.logger.info { "Current gas price #{gas_price}" }
      end
    end
  end
end
