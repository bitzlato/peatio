# frozen_string_literal: true

module Workers
  module Daemons
    class BlockchainProcessor < Base
      class Runner
        attr_reader :timestamp, :pid

        def initialize(blockchain, timestamp)
          @blockchain = blockchain
          @timestamp = timestamp
          @pid = nil
        end

        def start
          @pid ||= Process.fork do # rubocop:disable Naming/MemoizedInstanceVariableName
            ActiveRecord::Base.clear_active_connections!
            @blockchain.reload

            bc_service = BlockchainService.new(@blockchain)

            unless @blockchain.gateway.enable_block_fetching?
              Rails.logger.info { "Skip #{@blockchain.name} block processing." }
              return
            end
            Rails.logger.info { "Processing #{@blockchain.name} blocks." }

            loop do
              # Reset blockchain_service state.
              bc_service.reset!

              if @blockchain.reload.height + @blockchain.min_confirmations >= bc_service.latest_block_number
                Rails.logger.info { "Skip synchronization. No new blocks detected, height: #{@blockchain.height}, latest_block: #{bc_service.latest_block_number}." }
                Rails.logger.info { 'Sleeping for 10 seconds' }
                sleep(10)
                next
              end

              from_block = @blockchain.height || 0

              (from_block..bc_service.latest_block_number).each do |block_id|
                Rails.logger.info { "Started processing #{@blockchain.key} block number #{block_id}." }
                transactions_count = bc_service.process_block(block_id)
                Rails.logger.info { "Fetch #{transactions_count} transactions in block number #{block_id}." }
                bc_service.update_height(block_id)
                Rails.logger.info { "Finished processing #{@blockchain.key} block number #{block_id}." }
              rescue StandardError => e
                report_exception(e, true, blockchain_id: @blockchain.id, block_number: block_id)
                raise e
              end
            rescue StandardError => e
              report_exception(e, true, blockchain_id: @blockchain.id) unless e.is_a?(::EthereumGateway::AbstractCommand::NoReceiptFetched)
              Rails.logger.warn { "Error: #{e}. Sleeping for 10 seconds" }
              sleep(10)
            end
          end
        end

        def stop
          Process.kill('HUP', @pid)
        end
      end

      def run
        @runner_pool = ::Blockchain.active.each_with_object({}) do |b, pool|
          max_timestamp = [b.currencies.maximum(:updated_at), b.updated_at].compact.max.to_i

          logger.warn { "Creating the runner for #{b.key}" }
          pool[b.key] = Runner.new(b, max_timestamp).tap(&:start)
        end

        while running
          begin
            # Stop disabled blockchains runners first.
            (@runner_pool.keys - ::Blockchain.active.pluck(:key)).each do |b_key|
              logger.warn { "Stopping the runner for #{b_key} (blockchain is not active anymore)" }
              @runner_pool.delete(b_key).stop
            end

            # Recreate active blockchain runners by comparing runner &
            # maximum blockchain & currencies updated_at timestamp.
            ::Blockchain.active.each do |b|
              max_timestamp = [b.currencies.maximum(:updated_at), b.updated_at].compact.max.to_i

              if @runner_pool[b.key].blank?
                logger.warn { "Starting the new runner for #{b.key} (no runner found in pool)" }
                @runner_pool[b.key] = Runner.new(b, max_timestamp).tap(&:start)
              elsif @runner_pool[b.key].timestamp < max_timestamp
                logger.warn { "Recreating a runner for #{b.key} (#{Time.at(@runner_pool[b.key].timestamp)} < #{Time.at(max_timestamp)})" }
                @runner_pool.delete(b.key).stop
                @runner_pool[b.key] = Runner.new(b, max_timestamp).tap(&:start)
              else
                logger.warn { "The runner for #{b.key} is up to date (#{Time.at(@runner_pool[b.key].timestamp)} >= #{Time.at(max_timestamp)})" }
              end
            end

            logger.info { 'Current runners timestamps:' }
            logger.info do
              @runner_pool.transform_values(&:timestamp)
            end

            # Check for blockchain config changes in 30 seconds.
            sleep 30
          rescue StandardError => e
            raise e if is_db_connection_error?(e)

            report_exception(e)
            Rails.logger.warn { "Error: #{e}. Sleeping for 10 seconds" }
            sleep(10)
          end
        end
      end

      def stop
        @running = false
        @runner_pool.each { |_bc_key, runner| runner.stop }
      end
    end
  end
end
