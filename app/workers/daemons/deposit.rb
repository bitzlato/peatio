# frozen_string_literal: true

module Workers
  module Daemons
    class Deposit < Base
      self.sleep_time = 60

      def process
        # do nothing
      end

      def deposit_collection_fees!(deposit, deposit_spread)
        configs = {
          wallet:   @wallet.to_wallet_api_settings,
          currency: deposit.currency.to_blockchain_api_settings
        }

        if deposit.currency.parent_id?
          configs.merge!(parent_currency: deposit.currency.parent.to_blockchain_api_settings)
        end

        @adapter.configure(configs)
        deposit_transaction = Peatio::Transaction.new(hash:         deposit.txid,
                                                      txout:        deposit.txout,
                                                      to_address:   deposit.address,
                                                      block_number: deposit.block_number,
                                                      amount:       deposit.amount)

        transactions = @adapter.prepare_deposit_collection!(deposit_transaction,
                                                            # In #spread_deposit valid transactions saved with pending state
                                                            deposit_spread.select { |t| t.status.pending? },
                                                            deposit.currency.to_blockchain_api_settings)

        if transactions.present?
          updated_spread = deposit.spread.map do |s|
            deposit_options = s.fetch(:options, {}).symbolize_keys
            transaction_options = transactions.first.options.presence || {}
            general_options = deposit_options.merge(transaction_options)

            s.merge(options: general_options)
          end

          deposit.update(spread: updated_spread)

          transactions.each { |t| save_transaction(t.as_json.merge(from_address: @wallet.address), deposit) }
        end
        transactions
      end

      # TODO Сделать отдельный сервис для перевода депонированных средств на горячий
      def process_bak
        # Process deposits with `processing` state each minute
        ::Deposit.processing.each do |deposit|
          Rails.logger.info { "Starting processing coin deposit with id: #{deposit.id}." }

          # Check if adapter has prepare_deposit_collection! implementation
          if deposit.blockchain.gateway_implements?(:prepare_deposit_collection!)
            begin
              # Process fee collection for tokens
              collect_fee(deposit)
              # Will be processed after fee collection
              next if deposit.fee_processing?
            rescue StandardError => e
              Rails.logger.error { "Failed to collect deposit fee #{deposit.id}. See exception details below." }
              report_exception(e)
              deposit.err! e

              raise e if is_db_connection_error?(e)

              next
            end
          end

          process_deposit(deposit)
        end

        # Process deposits in `fee_processing` state that already transfered fees for collection
        ::Deposit.fee_processing.where('updated_at < ?', 5.minute.ago).each do |deposit|
          Rails.logger.info { "Starting processing token deposit with id: #{deposit.id}." }

          process_deposit(deposit)
        end
      end

      def process_deposit(deposit)
        deposit.spread_between_wallets!

        transactions = deposit.blockchain.gateway.collect_deposit!(deposit)

        if transactions.present?
          # Save txids in deposit spread.
          deposit.update!(spread: transactions.map(&:as_json))

          Rails.logger.warn { "The API accepted deposit collection and assigned transaction ID: #{transactions.map(&:as_json)}." }

          deposit.dispatch!
        else
          deposit.skip!
          "Skipped deposit with txid: #{deposit.txid} with amount: #{deposit.amount}"\
          " to #{deposit.address}"
        end
      rescue StandardError => e
        Rails.logger.error { "Failed to collect deposit #{deposit.id}. See exception details below." }
        report_exception(e)

        raise e if is_db_connection_error?(e)
      end

      def collect_fee(deposit)
        deposit.spread_between_wallets!

        fee_wallet = deposit.blockchain.wallets.active.fee.take
        unless fee_wallet
          Rails.logger.warn { "Can't find active fee wallet for currency with code: #{deposit.currency_id}."}
          return
        end

        transactions = WalletService.new(fee_wallet).deposit_collection_fees!(deposit, deposit.spread_to_transactions)
        deposit.fee_process! if transactions.present?
        Rails.logger.warn { "The API accepted token deposit collection fee and assigned transaction ID: #{transactions.map(&:as_json)}." }
      end

      # Record blockchain transactions in DB
      def save_transaction(transaction, reference)
        transaction['txid'] = transaction.delete('hash')
        Transaction.create!(transaction.merge(reference: reference))
      end
    end
  end
end
