# frozen_string_literal: true

if defined? Bugsnag
  Bugsnag.configure do |config|
    config.app_version = AppVersion.format('%M.%m.%p')

    config.notify_release_stages = %w[production staging sandbox]
    config.send_code = true
    config.send_environment = true
  end

  Bugsnag.before_notify_callbacks << lambda do |report|
    report.add_metadata(:context, :urlHost, ENV['URL_HOST']) if Rails.env.staging?
    report.add_metadata(:context, :requestId, Thread.current[:request_id]) if Thread.current[:request_id].present?
  end
end
