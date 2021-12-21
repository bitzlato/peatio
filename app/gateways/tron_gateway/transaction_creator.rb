# frozen_string_literal: true

class TronGateway
  module TransactionCreator
    def create_transaction!(from_address:,
                            to_address:,
                            amount:,
                            blockchain_address:,
                            contract_address: nil,
                            _meta: {}, **) # rubocop:disable lint/unusedmethodargument

      amount = amount.base_units if amount.is_a?(Money)

      args = {
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        private_key: blockchain_address.private_key.private_hex
      }

      if contract_address.present?
        args.merge!(contract_address: contract_address, fee_limit: (fee_limits[contract_address] || raise("Unknown fee limit for #{contract_address}")))
        create_trc20_transaction!(**args)
      else
        create_coin_transaction!(**args)
      end
    rescue Tron::Client::Error => e
      raise Peatio::Wallet::ClientError, e
    end

    private

    def create_coin_transaction!(from_address:, to_address:, amount:, private_key:)
      response = client.json_rpc(path: 'wallet/easytransferbyprivate',
                                 params: {
                                   privateKey: private_key,
                                   toAddress: reformat_decode_address(to_address),
                                   amount: amount
                                 })

      txid = response.dig('transaction', 'txID')

      unless txid
        raise Peatio::Wallet::ClientError, \
              "Withdrawal from #{from_address} to #{to_address} failed."
      end
      Peatio::Transaction.new(
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        hash: txid,
        options: response.slice('energy_used')
      ).freeze
    end

    def create_trc20_transaction!(from_address:, to_address:, amount:, private_key:, contract_address:, fee_limit:)
      txn = trigger_smart_contract(from_address: from_address, to_address: to_address,
                                   amount: amount, contract_address: contract_address, fee_limit: fee_limit)

      signed_txn = sign_transaction(transaction: txn, private_key: private_key)

      response = broadcast_transaction(signed_txn)

      txid = response.fetch('result', false) ? signed_txn.fetch('txID') : nil

      unless txid
        raise Peatio::Wallet::ClientError, \
              "Withdrawal from #{from_address} to #{to_address} failed."
      end

      Peatio::Transaction.new(
        from_address: from_address,
        to_address: to_address,
        amount: amount,
        hash: txid,
        contract_address: contract_address,
        options: { fee_limit: fee_limit }
      ).freeze
    end

    def sign_transaction(transaction:, private_key:)
      client.json_rpc(path: 'wallet/gettransactionsign',
                      params: {
                        transaction: transaction,
                        privateKey: private_key
                      })
    end

    def broadcast_transaction(signed_txn)
      client.json_rpc(path: 'wallet/broadcasttransaction', params: signed_txn)
    end

    def trigger_smart_contract(from_address:, to_address:, amount:, contract_address:, fee_limit:)
      client.json_rpc(path: 'wallet/triggersmartcontract',
                      params: {
                        contract_address: reformat_decode_address(contract_address),
                        function_selector: 'transfer(address,uint256)',
                        parameter: abi_encode(reformat_decode_address(to_address)[2..42], amount.to_s(16)),
                        fee_limit: fee_limit,
                        owner_address: reformat_decode_address(from_address)
                      }).fetch('transaction')
    end
  end
end
