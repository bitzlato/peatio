# frozen_string_literal: true

Rails.application.configure do
  config.cache_store = if ENV.true?('REDIS_CLUSTER')
                         [:redis_cache_store, { driver: :hiredis, cluster: [ENV.fetch('REDIS_URL')], password: ENV.fetch('REDIS_PASSWORD') }]
                       else
                         [:redis_cache_store, { driver: :hiredis, url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') }]
                       end
end
