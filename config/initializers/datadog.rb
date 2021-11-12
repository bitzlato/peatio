# frozen_string_literal: true

Datadog.configure do |c|
  # This will activate auto-instrumentation for Rails
  c.use :rails
  c.use :grape
  c.use :active_record
end

require 'datadog/statsd'

# Create a DogStatsD client instance.
STATS = Datadog::Statsd.new('localhost', 8125)
