cron_job: RAILS_ROOT=. bundle exec ruby ./lib/daemons/daemons.rb cron_job

withdraw_coin: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb withdraw_coin
matching: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb matching
order_processor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb order_processor
trade_executor: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb trade_executor
influx_writer: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb influx_writer
deposit_intention: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb deposit_intention
create_order: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb create_order
cancel_member_orders: RAILS_ROOT=. bundle exec ruby ./lib/daemons/amqp_daemon.rb cancel_member_orders

web: bundle exec rails server -b 0.0.0.0 -p 3000
