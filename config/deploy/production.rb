# frozen_string_literal: true

set :stage, :production
set :rails_env, :production
fetch(:default_env)[:rails_env] = :production
set :puma_bind, %w(tcp://0.0.0.0:9200)

set :systemd_amqp_daemon_instances, -> { %i[deposit_coin_address withdraw_coin deposit_intention matching order_processor trade_executor influx_writer] }
set :systemd_daemon_instances, -> { %i[cron_job blockchain] }

server ENV['PRODUCTION_SERVER'],
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons].freeze,
       ssh_options: { forward_agent: true }
