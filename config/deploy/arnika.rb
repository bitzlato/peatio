# frozen_string_literal: true

set :stage, :production
set :rails_env, :production
fetch(:default_env)[:rails_env] = :production
set :puma_bind, %w[tcp://0.0.0.0:9200]
set :puma_workers, 4
set :puma_threads, [4, 5]

set :markets, %w[
  btc_usdt btc_mcrerc20 eth_btc eth_usdt usdt_mcrerc20
  bnbbep20_usdt hthrc20_usdt mdterc20_mcrerc20
  matic_usdt avax_usdt trx_usdt daierc20_usdt bzb_usdt
]

server ENV['PRODUCTION_SERVER_ARNIKA'],
       user: fetch(:user),
       port: '22',
       roles: %w[db app amqp_daemons].freeze,
       primary: true,
       ssh_options: { forward_agent: true }

