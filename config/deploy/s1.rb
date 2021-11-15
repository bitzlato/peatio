# frozen_string_literal: true

set :rails_env, :staging
set :disallow_pushing, false
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :systemd_daemon_instances, -> { %i[cron_job] }

set :systemd_amqp_daemon_instances,
    %i[
      balances_updating
      cancel_member_orders
      create_order
      deposit_coin_address
      deposit_intention
      influx_writer
      trade_completed
      withdraw_coin
      trade_executor
      matching
      order_processor
    ]

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
