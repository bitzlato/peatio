# frozen_string_literal: true

set :stage, :production
set :rails_env, :production
fetch(:default_env)[:rails_env] = :production
set :puma_bind, %w[tcp://0.0.0.0:9200]

set :systemd_daemon_instances, -> { %i[cron_job blockchain] }

server ENV['PRODUCTION_SERVER'],
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons].freeze,
       ssh_options: { forward_agent: true }

server ENV['PRODUCTION_SERVER2'],
       user: fetch(:user),
       port: '22',
       roles: %w[app].freeze,
       ssh_options: { forward_agent: true }
