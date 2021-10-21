# frozen_string_literal: true

class EthereumGateway
  class FromTransferer < AbstractCommand
    NONCE_LOCK_TTL = 1.minute.to_i * 1000

    Error = Class.new StandardError
    NonceLocked = Class.new(Error)

    def initialize(client)
      @lock_manager = Redlock::Client.new([ENV.fetch('REDIS_URL', 'redis://localhost:6379')])
      super(client)
    end

    def call(from_address:, # rubocop:disable Metrics/ParameterLists
             secret:,
             blockchain_address:,
             contract_address:,
             sender:,
             recipient:,
             amount:,
             gas_limit:,
             chain_id:,
             nonce: nil,
             gas_price: nil,
             gas_factor: 1)
      raise "amount (#{amount.class}) must be an Integer (base units)" unless amount.is_a? Integer
      raise 'No gas limit' if gas_limit.nil?
      raise Error, 'zero amount transction' if amount.zero?

      gas_price ||= (fetch_gas_price * gas_factor).to_i
      raise 'gas price zero' if gas_price.zero?

      data = abi_encode('transferFrom(address,address,uint256)', normalize_address(sender), normalize_address(recipient), '0x' + amount.to_s(16))
      logger.info(message: 'Create erc20 transaction', from_address: from_address, sender: sender, recipient: recipient, contract_address: contract_address, amount: amount, gas_price: gas_price, gas_limit: gas_limit)
      validate_txid!(
        if blockchain_address.present?
          create_raw_transaction!(blockchain_address, {
                                    data: data,
                                    gas_limit: gas_limit,
                                    gas_price: gas_price,
                                    to: contract_address,
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
    end

    private

    def create_raw_transaction!(blockchain_address, params)
      logger.info { { message: 'Create raw transaction', blockchain_address_id: blockchain_address.id } }
      nonce_lock_key = "nonce_lock:#{blockchain_address.id}"
      lock_info = @lock_manager.lock(nonce_lock_key, NONCE_LOCK_TTL)
      raise NonceLocked unless lock_info

      transaction_count = client.json_rpc(:eth_getTransactionCount, [blockchain_address.address, 'latest']).to_i(16)
      tx = Eth::Tx.new(params.merge(nonce: transaction_count))
      tx.sign(blockchain_address.private_key)
      result = client.json_rpc(:eth_sendRawTransaction, [tx.hex])
      @lock_manager.unlock(lock_info)
      result
    end
  end
end
