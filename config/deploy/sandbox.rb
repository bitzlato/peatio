# frozen_string_literal: true

set :rails_env, :sandbox
set :disallow_pushing, false
set :application, -> { 'peatio-sandbox' }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }
set :markets, %w[eth_bnb]

set :systemd_daemon_instances,
    %i[bargainer_job blockchain_processor collector currency_pricer gas_price_checker k_line liabilities_compactor payment_address_balancer remove_invoiced_deposits stats_member_pnl ticker wallet_balances]

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons market_amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
