# frozen_string_literal: true

require 'rake'

Peatio::Application.load_tasks

module Workers
  module Daemons
    module LiabilitiesCompactor
      @sleep_time = 24.hours

      def process
        Rake::Task['job:liabilities:compact_orders'].invoke
      end
    end
  end
end
