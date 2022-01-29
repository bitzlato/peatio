# frozen_string_literal: true

require 'rake'

Peatio::Application.load_tasks

module Workers
  module Daemons
    class LiabilitiesCompactor < Base
      @sleep_time = 1.hour

      def process
        return unless Time.current.hour == 1

        Rails.logger.info { { message: 'Start liabilities compactor' } }
        Rake::Task['job:liabilities:compact_orders'].execute
        Rails.logger.info { { message: 'Finish liabilities compactor' } }
      end
    end
  end
end
