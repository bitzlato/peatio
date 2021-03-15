# Run polling process for supported gateways
module Jobs
  module Cron
    module DepositsPolling
      def self.process
        Wallet.active.find_each do |w|
          ws = WalletService.new(w)
          ws.poll_intentions! if ws.support_polling?
        rescue StandardError => e
          report_exception_to_screen(e)
          next
        end
        sleep 10
      end
    end
  end
end
