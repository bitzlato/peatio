# frozen_string_literal: true

module Workers
  module Daemons
    class Base
      class GetLockError < StandardError; end
      class << self; attr_accessor :sleep_time end

      attr_accessor :running
      attr_reader :logger

      def initialize
        @running = true
        @logger = Rails.logger
      end

      def stop
        @running = false
      end

      def run
        Rails.logger.info { { message: 'Start worker', service: self.class.name } }

        while running
          begin
            process
          rescue ScriptError => e
            raise e if is_db_connection_error?(e)

            report_exception(e, true, service: self.class.name)
          rescue StandardError => e
            report_exception(e, true, service: self.class.name)
            sleep 30
          end
          wait(self.class.sleep_time.to_i)
        end
      end

      def process
        method_not_implemented
      end

      def wait(seconds)
        while seconds.positive?
          sleep(1)
          seconds -= 1
          break unless @running
        end
      end
    end
  end
end
