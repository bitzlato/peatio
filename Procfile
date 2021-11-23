bargainer_job: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb bargainer_job
blockchain_processor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb blockchain_processor
collector: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb collector
currency_pricer: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb currency_pricer
gas_price_checker: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb gas_price_checker
k_line: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb k_line
liabilities_compactor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb liabilities_compactor
payment_address_balancer: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb payment_address_balancer
remove_invoiced_deposits: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb remove_invoiced_deposits
stats_member_pnl: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb stats_member_pnl
ticker: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb ticker
transfers_polling: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb transfers_polling
wallet_balances: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb wallet_balances

balances_updating: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb balances_updating
cancel_member_orders: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb cancel_member_orders
create_order: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb create_order
deposit_intention: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb deposit_intention
influx_writer: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb influx_writer
matching: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb matching
order_cancellator: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb order_cancellator
order_processor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb order_processor
trade_executor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb trade_executor
withdraw_coin: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb withdraw_coin

web: bundle exec rails server -b 0.0.0.0 -p 3000
