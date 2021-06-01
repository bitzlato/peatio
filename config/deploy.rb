# frozen_string_literal: true

lock '3.16'

set :user, 'app'
set :application, 'peatio'

set :roles, %w[app db].freeze

set :repo_url, ENV.fetch('DEPLOY_REPO', `git remote -v | grep origin | head -1 | awk  '{ print $2 }'`) if ENV['USE_LOCAL_REPO'].nil?
set :keep_releases, 10

set :linked_files, %w[.env]
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets]
set :config_files, fetch(:linked_files)

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :disallow_pushing, true

set :db_dump_extra_opts, '--force'

set :branch, ENV.fetch('BRANCH', 'main')
#  ask(:branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp })

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :conditionally_migrate, true # Only attempt migration if db/migrate changed - not related to Webpacker, but a nice thing

set :db_local_clean, false
set :db_remote_clean, true

set :app_version, SemVer.find.to_s
set :current_version, `git rev-parse HEAD`.strip

set :sentry_organization, ENV['SENTRY_ORGANIZATION']
set :sentry_release_version, -> { [fetch(:app_version), fetch(:current_version)].join('-') }

set :puma_init_active_record, true
set :puma_control_app, true
set :puma_threads, [4, 16]
set :puma_tag, fetch(:application)
set :puma_daemonize, false
set :puma_preload_app, false
set :puma_prune_bundler, true
set :puma_init_active_record, true
set :puma_workers, 0
set :puma_bind, %w(tcp://0.0.0.0:9200)
set :puma_start_task, 'systemd:puma:start'

set :init_system, :systemd

set :systemd_daemon_role, :app
set :systemd_daemon_instances, -> { %i[cron_job] }

set :systemd_amqp_daemon_role, :app
set :systemd_amqp_daemon_instances, -> { %i[withdraw_coin matching order_processor trade_executor influx_writer] }

before 'deploy:starting', 'sentry:validate_config'
after 'deploy:published', 'sentry:notice_deployment'

after 'deploy:publishing', 'systemd:puma:reload-or-restart'
# after 'deploy:publishing', 'systemd:daemon:reload-or-restart'
# after 'deploy:publishing', 'systemd:amqp_daemon:reload-or-restart'
