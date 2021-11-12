# frozen_string_literal: true

set :rails_env, :sandbox
set :disallow_pushing, false
set :application, -> { 'peatio-sandbox' }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }
set :markets, %w[eth_bnb]

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons market_amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
