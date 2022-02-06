# frozen_string_literal: true

if defined? Bugsnag
  Bugsnag.configure do |config|
    config.app_version = AppVersion.format('%M.%m.%p')

    config.notify_release_stages = %w[production staging sandbox]
    config.send_code = true
    config.send_environment = true

    config.add_metadata(:context, :urlHost, ENV['URL_HOST']) if Rails.env.staging?
    config.add_on_error(proc do |event|
      event.add_metadata(:context, :requestId, Thread.current[:request_id]) if Thread.current[:request_id].present?
    end)
  end
end
