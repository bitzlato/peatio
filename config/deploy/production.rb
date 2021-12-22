# frozen_string_literal: true

set :stage, :production
set :rails_env, :production
fetch(:default_env)[:rails_env] = :production
set :puma_bind, %w[tcp://0.0.0.0:9200]
set :puma_workers, 4
set :puma_threads, [4, 5]

set :markets, %w[
  btc_usdterc20 btc_mcrerc20 eth_btc
  eth_usdterc20 eth_usdcerc20 eth_mcrerc20
  usdterc20_mcrerc20 usdterc20_usdtbep20 usdterc20_usdcerc20
  usdcerc20_usdcbep20 bnbbep20_usdtbep20 bnbbep20_usdcbep20
  usdthrc20_usdtbep20 usdthrc20_usdterc20 usdchrc20_usdcerc20
  usdchrc20_usdcbep20 hthrc20_usdthrc20 hthrc20_usdchrc20
  mdterc20_mcrerc20 mdterc20_usdterc20 matic_usdtplgn matic_usdcplgn
  usdterc20_usdtplgn usdcerc20_usdcplgn usdtbep20_usdtplgn
  usdcbep20_usdcplgn usdthrc20_usdtplgn usdchrc20_usdcplgn
]

server ENV['PRODUCTION_SERVER'],
       user: fetch(:user),
       port: '22',
       roles: %w[db app amqp_daemons].freeze,
       primary: true,
       ssh_options: { forward_agent: true }

server ENV['PRODUCTION_SERVER2'],
       user: fetch(:user),
       port: '22',
       roles: %w[daemons].freeze,
       ssh_options: { forward_agent: true }

server ENV['PRODUCTION_SERVER3'],
       user: fetch(:user),
       port: '22',
       roles: %w[market_amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
