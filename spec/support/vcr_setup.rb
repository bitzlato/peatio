# frozen_string_literal: true

VCR.configure do |config|
  config.cassette_library_dir = "#{::Rails.root}/spec/cassettes"
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
  # config.ignore_localhost = true
  # config.configure_rspec_metadata!
end
