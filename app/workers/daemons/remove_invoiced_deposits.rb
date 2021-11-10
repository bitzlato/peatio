# frozen_string_literal: true

module Workers
  module Daemons
    class RemoveInvoicedDeposits < Base
      @sleep_time = 10.minutes

      def process
        Deposit.invoiced.where('invoice_expires_at < ?', Time.now).find_each do |deposit|
          deposit.cancel!
          Rails.logger.info("Deposit with id: #{deposit.id} has been transfered to the canceled state")
        end
      end
    end
  end
end
