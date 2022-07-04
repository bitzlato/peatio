# frozen_string_literal: true

set :rails_env, :staging
set :disallow_pushing, false
set :application, -> { 'peatio-' + fetch(:stage).to_s }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :puma_bind, -> { ["tcp://0.0.0.0:965#{fetch(:stage)[1].to_i || 9}", "unix://#{shared_path}/tmp/sockets/puma.sock"] }

set :systemd_daemon_instances,
    %i[
      currency_pricer
      k_line
      liabilities_compactor
      payment_address_balancer
      stats_member_pnl
      swap_order_status_checker
      ticker
      wallet_balances
    ]

set :systemd_amqp_daemon_instances,
    %i[
      balances_updating
      cancel_member_orders
      create_order
      deposit_coin_address
      deposit_processor
      influx_writer
      trade_completed
      trade_executor
      matching
      order_processor
      order_cancellator
      withdrawal_processor
    ]

server ENV.fetch('STAGING_SERVER'),
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
