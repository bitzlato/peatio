# frozen_string_literal: true

set :rails_env, :staging
set :disallow_pushing, false
set :application, -> { 'peatio-' + fetch(:stage).to_s }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :systemd_daemon_instances, -> { %i[bargainer_job currency_pricer k_line liabilities_compactor remove_invoiced_deposits stats_member_pnl ticker swap_order_status_checker] }

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
      order_cancellator
    ]

server ENV.fetch('STAGING_SERVER'),
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
