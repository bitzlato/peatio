# frozen_string_literal: true

module Workers
  module AMQP
    class BalancesUpdating < Base
      def process(payload)
        payload.symbolize_keys!
        blockchain = Blockchain.find(payload[:blockchain_id])
        address = payload[:address]

        BalancesUpdater.new(blockchain: blockchain, address: address).perform
      rescue ActiveRecord::RecordNotFound => e
        report_exception(e, true, payload)
      end
    end
  end
end
