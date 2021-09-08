module Jobs
  module Cron
    class Collector
      def self.process
        return unless Rails.env.production?
        new.process
        sleep 60
      end

      def process
        # TODO select only payment addresses with enough balance
        PaymentAddress.collection_required.lock.each do |pa|
          next unless pa.collectable_balance?
          if pa.has_enough_gas?
            pa.collect!
          else
            pa.refuel_gas!
          end
        end
      end
    end
  end
end
