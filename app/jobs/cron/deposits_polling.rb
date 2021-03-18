# Run polling process for supported gateways
module Jobs
  module Cron
    # TODO rename to transfer polling
    module DepositsPolling
      def self.process
        Wallet.active.find_each do |w|
          next unless ws.support_polling?
          WalletService
            .new(w)
            .poll_transfers!
        rescue StandardError => e
          report_exception_to_screen(e)
        end
        sleep 10
      end
    end
  end
end
