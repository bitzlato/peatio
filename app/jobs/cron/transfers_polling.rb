# Run polling process for supported gateways
module Jobs
  module Cron
    module TransfersPolling
      def self.process
        Wallet.active.find_each do |w|
          ws = WalletService .new(w)
          poll_deposits ws if ws.support_deposits_polling?
          poll_withdraws ws if ws.support_withdraws_polling?
        end
        sleep 10
      rescue StandardError => e
        report_exception(e)
      end

      def self.poll_withdraws(ws)
        ws.poll_withdraws!
      rescue StandardError => e
        report_exception(e)
      end

      def self.poll_deposits(ws)
        ws.poll_deposits!
      rescue StandardError => e
        report_exception(e)
      end
    end
  end
end
