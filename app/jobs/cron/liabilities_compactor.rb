# frozen_string_literal: true

require 'rake'

Peatio::Application.load_tasks

module Jobs
  module Cron
    module LiabilitiesCompactor
      JOB_TIMEOUT = 24.hours

      def self.process(job_timeout = JOB_TIMEOUT)
        Rake::Task['job:liabilities:compact_orders'].invoke

        sleep job_timeout
      end
    end
  end
end
