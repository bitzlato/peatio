module Jobs
  module Cron
    class Collector
      def self.process
        return # TODO
        new.process
        sleep 300
      end

      def process
        # TODO select only payment addresses with enough balance
        PaymentAddress.collection_required.lock.each do |pa|
          next unless pa.collectable_balance?
          if pa.has_enough_gas_to_collect?
            pa.collect!
          else
            pa.refuel_gas!
          end
        rescue => err
          report_exception err, true, payment_address_id: pa.id
        end
      end
    end
  end
end
