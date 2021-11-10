# frozen_string_literal: true

set :rails_env, :sandbox
set :disallow_pushing, false
set :application, -> { 'peatio-sandbox' }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :systemd_daemon_instances, -> { %i[cron_job blockchain] }

set :systemd_amqp_daemon_instances,
    lambda {
      %i[
        balances_updating
        cancel_member_orders
        create_order
        deposit_coin_address
        influx_writer
        matching
        order_processor
        trade_executor
        withdraw_coin
      ]
    }

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db amqp_daemons daemons].freeze,
       ssh_options: { forward_agent: true }
