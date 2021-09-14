# frozen_string_literal: true

module Jobs
  module Cron
    class RemoveInvoicedDeposits
      JOB_TIMEOUT = 10.minutes

      def self.process
        Deposit.invoiced.where('invoice_expires_at < ?', Time.now).find_each do |deposit|
          deposit.cancel!
          Rails.logger.info("Deposit with id: #{deposit.id} has been transfered to the canceled state")
        end
        sleep(JOB_TIMEOUT)
      end
    end
  end
end
