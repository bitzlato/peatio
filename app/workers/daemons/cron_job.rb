# frozen_string_literal: true

module Workers
  module Daemons
    class CronJob < Base
      JOBS = [
        # Jobs::Cron::AML,
      ].freeze

      def run
        Rails.logger.info 'Start cron_job'
        @threads = JOBS.map { |j| Thread.new { process(j) } }
        @threads.map(&:join)
      end

      def process(service)
        while running
          begin
            service.process
          rescue StandardError => e
            report_exception e, true, service: service
            sleep 30
          end
        end
      end

      def stop
        super
        Array(@threads).each { |t| Thread.kill t }
      end
    end
  end
end
