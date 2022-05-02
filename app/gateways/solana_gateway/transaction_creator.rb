# frozen_string_literal: true

class SolanaGateway
  class TransactionCreator < Base
    Error = Class.new StandardError

    # @param amount - in base units (cents)
    def perform(amount:,
             from_address:,
             to_address:,
             fee_payer_address:,
             signers:,
             contract_address: nil,
             subtract_fee: false)

      raise "amount (#{amount.class}) must be Money (not base units)" unless amount.is_a? Money
      # raise "can't subtract_fee for erc20 transaction" if subtract_fee && contract_address.present?
      raise Error, 'zero amount transaction' if amount.base_units.zero?

      peatio_transaction = create_transaction!({
                                                 amount: amount,
                                                 from_address: from_address,
                                                 to_address: to_address,
                                                 fee_payer_address: fee_payer_address,
                                                 signers: signers,
                                                 contract_address: contract_address})
      peatio_transaction
    end

    def create_transaction!(from_address:,
                                to_address:,
                                amount:,
                                fee_payer_address:,
                                signers:,
                                contract_address: nil)

      raise 'amount must be money' unless amount.is_a? Money


      # Subtract fees from initial deposit amount in case of deposit collection
      if amount.base_units.positive?
        logger.info("Create transaction #{from_address} -> #{to_address} amount:#{amount.base_units}")
      else
        logger.warn("Skip transaction (amount is not positive) #{from_address} -> #{to_address} amount:#{amount.base_units}")
        raise Error, "Amount is not positive (#{amount.base_units}) for #{from_address} to #{to_address}"
      end
      txid = validate_txid!(
        if signers.any?
          create_raw_transaction!(
                                  from_pubkey: from_address,
                                  to_pubkey: to_address,
                                  fee_payer: fee_payer_address || from_address,
                                  amount: amount,
                                  signers: signers,
                                  contract_address: contract_address
                                )
        else
          raise 'No signers!'
        end
      )

      Peatio::Transaction.new(
        from_address: from_address,
        to_address: to_address,
        amount: amount.base_units,
        hash: txid,
        contract_address: contract_address,
        fee_payer_address: fee_payer_address
      ).freeze
    end

    private

    def create_raw_transaction!(from_pubkey:, to_pubkey:, fee_payer:, amount:, signers: [], contract_address:)
      tx = Solana::Tx.new
      if contract_address
        from_owner = token_parent_from_pubkey(from_pubkey, amount)
        token_account_pubkey = get_token_account_pubkey_from_pubkey(to_pubkey, contract_address, from_owner)
        instruction = Solana::Program::Token.transfer_checked_instruction(
          from_pubkey: from_owner.address, from_token_account_pubkey: from_pubkey,
          to_token_account_pubkey: token_account_pubkey, token_pubkey: contract_address,
          amount: amount.base_units, decimals: amount.currency.exponent
        )
      else
        instruction = Solana::Program::System.transfer_instruction(from_pubkey: from_pubkey, to_pubkey: to_pubkey, lamports: amount.base_units)
      end
      tx.add(instruction)
      tx.recent_blockhash = api.get_recent_blockhash
      tx.fee_payer = fee_payer
      tx.sign(signers)
      txid = api.send_transaction(tx.to_base64)
      txid
    end

    def validate_txid!(txid)
      unless valid_txid? txid
        raise Solana::Client::Error, \
              "Transaction failed (invalid txid #{txid})."
      end
      txid
    end

    def valid_txid?(txid)
      true
    end

    def token_parent_from_pubkey(from_pubkey, amount)
      payment_address = blockchain.payment_addresses.where(address: from_pubkey, blockchain_currency_id: amount.currency.blockchain_currency_record).first
      return payment_address.parent if payment_address

      blockchain_currency = amount.currency.blockchain_currency_record
      blockchain_currency = blockchain_currency.parent if blockchain_currency.parent.present?

      wallet = blockchain.wallets.where(address: from_pubkey).with_currency(blockchain_currency.currency).first
      return wallet.parent if wallet.present?
    end

    def get_token_account_pubkey_from_pubkey(to_pubkey, contract_address, signer)
      info = api.get_account_info(to_pubkey)
      if info.dig(:value, :owner) == Solana::Program::Token::PROGRAM_ID
        to_pubkey
      else
        token = gateway.find_or_create_token_account(to_pubkey, contract_address, signer)
        sleep(30) # wait about 30 blocks
        token
      end
    end
  end
end
