# frozen_string_literal: true

class EthereumGateway
  class TransactionCreator < AbstractCommand
    NONCE_LOCK_TTL = 1.minute.to_i * 1000

    Error = Class.new StandardError
    NonceLocked = Class.new(Error)

    def initialize(client)
      @lock_manager = Redlock::Client.new([ENV.fetch('REDIS_URL', 'redis://localhost:6379')])
      super(client)
    end

    # @param amount - in base units (cents)
    def call(amount:, # rubocop:disable Metrics/ParameterLists
             from_address:,
             to_address:,
             gas_limit:, secret: nil,
             blockchain_address: nil,
             nonce: nil,
             contract_address: nil,
             subtract_fee: false,
             gas_price: nil,
             gas_factor: 1,
             chain_id: nil)
      raise "amount (#{amount.class}) must be an Integer (base units)" unless amount.is_a? Integer
      raise "can't subtract_fee for erc20 transaction" if subtract_fee && contract_address.present?
      raise 'No gas limit' if gas_limit.nil?
      raise Error, 'zero amount transaction' if amount.zero?
      raise 'Must be secret either blockchain_address' if secret.nil? && blockchain_address.nil?

      gas_price ||= (fetch_gas_price * gas_factor).to_i

      raise 'gas price zero' if gas_price.zero?

      peatio_transaction = if contract_address.present?
                             create_erc20_transaction!(amount: amount,
                                                       from_address: from_address,
                                                       to_address: to_address,
                                                       contract_address: contract_address,
                                                       secret: secret,
                                                       blockchain_address: blockchain_address,
                                                       nonce: nonce,
                                                       gas_limit: gas_limit,
                                                       gas_price: gas_price,
                                                       chain_id: chain_id)
                           else
                             create_eth_transaction!(amount: amount,
                                                     from_address: from_address,
                                                     to_address: to_address,
                                                     subtract_fee: subtract_fee,
                                                     secret: secret,
                                                     blockchain_address: blockchain_address,
                                                     nonce: nonce,
                                                     gas_limit: gas_limit,
                                                     gas_price: gas_price,
                                                     chain_id: chain_id)
                           end
      peatio_transaction.options.merge! gas_factor: gas_factor
      peatio_transaction
    end

    def create_eth_transaction!(from_address:,
                                to_address:,
                                amount:,
                                secret:,
                                blockchain_address:,
                                gas_limit:,
                                gas_price:,
                                nonce: nil,
                                subtract_fee: false,
                                chain_id: nil)

      raise 'amount must be an integer' unless amount.is_a? Integer

      # Subtract fees from initial deposit amount in case of deposit collection
      amount -= gas_limit.to_i * gas_price.to_i if subtract_fee

      if amount.positive?
        logger.info("Create eth transaction #{from_address} -> #{to_address} amount:#{amount} gas_price:#{gas_price} gas_limit:#{gas_limit}")
      else
        logger.warn("Skip eth transaction (amount is not positive) #{from_address} -> #{to_address} amount:#{amount} gas_price:#{gas_price} gas_limit:#{gas_limit}")
        raise Error, "Amount is not positive (#{amount}) for #{from_address} to #{to_address}"
      end
      txid = validate_txid!(
        if blockchain_address.present?
          create_raw_transaction!(blockchain_address, {
                                    data: '',
                                    gas_limit: gas_limit,
                                    gas_price: gas_price,
                                    to: normalize_address(to_address),
                                    value: amount,
                                    chain_id: chain_id
                                  })
        elsif secret.present?
          client
            .json_rpc(:personal_sendTransaction,
                      [{
                        from: normalize_address(from_address),
                        to: normalize_address(to_address),
                        nonce: nonce.nil? ? nil : '0x' + nonce.to_i.to_s(16),
                        value: '0x' + amount.to_s(16),
                        gas: '0x' + gas_limit.to_i.to_s(16),
                        gasPrice: '0x' + gas_price.to_i.to_s(16)
                      }.compact,
                       secret])
        else
          raise 'No secret or blockchain_address'
        end
      )

      Peatio::Transaction.new(
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        hash: normalize_address(txid),
        options: {
          gas_price: gas_price,
          gas_limit: gas_limit,
          subtract_fee: subtract_fee
        }
      ).freeze
    end

    def create_erc20_transaction!(from_address:,
                                  to_address:,
                                  amount:,
                                  contract_address:,
                                  secret:,
                                  blockchain_address:,
                                  gas_limit:,
                                  gas_price:,
                                  nonce: nil,
                                  chain_id: nil)
      data = abi_encode('transfer(address,uint256)', normalize_address(to_address), '0x' + amount.to_s(16))

      logger.info("Create erc20 transaction #{from_address} -> #{to_address} contract_address: #{contract_address} amount:#{amount} gas_price:#{gas_price} gas_limit:#{gas_limit}")
      txid = validate_txid!(
        if blockchain_address.present?
          create_raw_transaction!(blockchain_address, {
                                    data: data,
                                    gas_limit: gas_limit,
                                    gas_price: gas_price,
                                    to: contract_address,
                                    value: 0,
                                    chain_id: chain_id
                                  })
        elsif secret.present?
          client.json_rpc(:personal_sendTransaction,
                          [{
                            from: normalize_address(from_address),
                            nonce: nonce.nil? ? nil : '0x' + nonce.to_i.to_s(16),
                            to: contract_address,
                            data: data,
                            gas: '0x' + gas_limit.to_i.to_s(16),
                            gasPrice: '0x' + gas_price.to_i.to_s(16)
                          }.compact, secret])
        else
          raise 'No secret or blockchain_address'
        end
      )
      Peatio::Transaction.new(
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        hash: normalize_address(txid),
        contract_address: contract_address,
        options: {
          gas_price: gas_price,
          gas_limit: gas_limit
        }
      ).freeze
    end

    private

    def create_raw_transaction!(blockchain_address, params)
      logger.info { { message: 'Create raw transaction', blockchain_address_id: blockchain_address.id } }
      nonce_lock_key = "nonce_lock:#{blockchain_address.id}"
      lock_info = @lock_manager.lock(nonce_lock_key, NONCE_LOCK_TTL)
      logger.info { { message: 'Raw transaction nonce is locked', blockchain_address_id: blockchain_address.id, lock_info: lock_info } }
      raise NonceLocked unless lock_info

      transaction_count = client.json_rpc(:eth_getTransactionCount, [blockchain_address.address, 'latest']).to_i(16)
      logger.info { { message: 'Transaction count is fetched', blockchain_address_id: blockchain_address.id, transaction_count: transaction_count } }
      tx = Eth::Tx.new(params.merge(nonce: transaction_count))
      tx.sign(EthereumGateway.private_key(blockchain_address.private_key_hex))
      result = client.json_rpc(:eth_sendRawTransaction, [tx.hex])
      @lock_manager.unlock(lock_info)
      result
    end
  end
end
