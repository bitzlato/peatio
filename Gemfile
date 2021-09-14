# encoding: UTF-8
# frozen_string_literal: true

source 'https://rubygems.org'

ruby File.read('.ruby-version')

gem 'ransack', '~> 2.3.2'
gem 'rails', '~> 5.2.4.5'
gem 'puma', '~> 5.0'
gem 'redis', '~> 4.1.2', require: ['redis', 'redis/connection/hiredis']
gem 'hiredis', '~> 0.6.0'
gem 'figaro', '~> 1.1.1'
gem 'hashie', '~> 3.6.0'
gem 'aasm', '~> 5.2.0'
gem 'bunny', '~> 2.14.1'
gem 'cancancan', '~> 3.1.0'
gem 'enumerize', '~> 2.2.2'
gem 'kaminari', '~> 1.2.1'
gem 'rbtree', '~> 0.4.2'

gem 'grape', '~> 1.5', '>= 1.5.3'
gem 'grape-entity', '~> 0.9.0'
gem 'grape_logging', '~> 1.8', '>= 1.8.4'
gem 'grape-swagger', '~> 1.4'
gem 'grape-swagger-entity', '~> 0.5.1'

gem 'rack-attack', '~> 5.4.2'
gem 'faraday'
gem 'faraday_middleware'
gem 'faye', '~> 1.4'
gem 'eventmachine', '~> 1.2'
gem 'em-synchrony', '~> 1.0'
gem "strip_attributes"
gem 'amazing_print'

# We use 2.3.0.dev for bitzlato client
# Fill free to update to rubygem version when it will be released
gem 'jwt', github: 'jwt/ruby-jwt'

gem 'email_validator', '~> 1.6.0'
gem 'validate_url', '~> 1.0.4'
gem 'god', '~> 0.13.7', require: false
gem 'arel-is-blank', '~> 1.0.0'
gem 'bugsnag'
gem 'memoist', '~> 0.16.0'
gem 'method-not-implemented', '~> 1.0.1'
gem 'validates_lengths_from_database', '~> 0.7.0'
gem 'jwt-multisig', '~> 1.0.0'
gem 'cash-addr', '~> 0.2.0', require: 'cash_addr'
gem 'digest-sha3', '~> 1.1.0'
gem 'scout_apm', '~> 2.4', require: false
gem 'peatio', github: 'bitzlato/peatio-core'
gem 'rack-cors', '~> 1.0.6', require: false
gem 'jwt-rack', '~> 0.1.0', require: false
gem 'env-tweaks', '~> 1.0.0'
gem 'vault', '~> 0.12', require: false
gem 'vault-rails', '~> 0.7.1'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'net-http-persistent', '~> 3.0.1'
gem 'influxdb', '~> 0.7.0'
gem 'safe_yaml', '~> 1.0.5', require: 'safe_yaml/load'
gem 'composite_primary_keys'
gem 'dotenv'

gem 'adequate_crypto_address'

# Security versions of deep dependencies
gem "addressable", ">= 2.8.0"
gem "rexml", ">= 3.2.5"

# Yeah! We use pry in production!
gem 'pry-byebug',   '~> 3.7'

gem 'money', github: 'bitzlato/money', branch: 'main'

group :development, :test do
  gem 'irb'
  gem 'bump',         '~> 0.7'
  gem 'faker',        '~> 1.8'
  gem 'bullet',       '~> 5.9'
  gem 'grape_on_rails_routes', '~> 0.3.2'
  gem 'parallel_tests'
end

group :development do
  gem 'rubocop'
  gem "rubocop-rspec", "~> 2.4"
  gem 'rubocop-rails'
  gem 'foreman'
  gem 'annotate'
  gem 'ruby-prof',  '~> 0.17.0', require: false
  gem 'listen',     '>= 3.0.5', '< 3.2'

  gem 'rspec'
  gem 'guard'
  gem 'guard-rspec', github: 'caspark/guard-rspec' # Use from github to remove rspec < 4.0 dependencies
end

group :test do
  gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
  gem 'rspec-retry',         '~> 0.6'
  gem 'webmock',             '~> 3.5'
  gem 'database_cleaner-active_record'
  gem 'mocha',               '~> 1.8', require: false
  gem 'factory_bot_rails', '~> 5.0', '>= 5.0.2'
  gem 'timecop',             '~> 0.9'
end

# Load gems from Gemfile.plugin.
Dir.glob File.expand_path('../Gemfile.plugin', __FILE__) do |file|
  eval_gemfile file
end

gem "pg", "~> 1.2"

gem "http_accept_language", "~> 2.1"

gem "semver2", "~> 3.4"

gem 'pry-rails'

group :deploy do
  gem 'capistrano-dotenv'
  gem 'capistrano-dotenv-tasks'
  gem 'capistrano3-puma', github: 'seuros/capistrano-puma'
  gem 'capistrano', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano-shell', require: false
  gem 'capistrano-db-tasks', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-tasks', github: 'brandymint/capistrano-tasks', require: false
  gem 'capistrano-systemd-multiservice', github: 'groovenauts/capistrano-systemd-multiservice', require: false
  # gem 'capistrano-master-key', require: false, github: 'virgoproz/capistrano-master-key'
  gem 'capistrano-git-with-submodules'
  gem 'bugsnag-capistrano', require: false
  gem 'slackistrano', require: false
end

gem "sd_notify", "~> 0.1.1"

gem "active_record_upsert"

# Fixes:   [DEPRECATION] :after_commit AASM callback is not safe in terms of race conditions and redundant calls.
#           Please add `gem 'after_commit_everywhere', '~> 1.0'` to your Gemfile in order to fix that.
gem "after_commit_everywhere", "~> 1.1"

gem "request_store", "~> 1.5"

gem "faraday-detailed_logger", "~> 2.3"
gem "faraday_curl", "~> 0.0.2"
