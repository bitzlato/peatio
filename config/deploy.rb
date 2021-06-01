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

# set :db_dump_dir, "./db"
set :db_dump_extra_opts, '--force'

set :branch, ENV.fetch('BRANCH', 'main')
#  ask(:branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp })

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :conditionally_migrate, true # Only attempt migration if db/migrate changed - not related to Webpacker, but a nice thing

set :puma_init_active_record, true

set :db_local_clean, false
set :db_remote_clean, true

set :puma_control_app, true
set :puma_threads, [2, 4]
set :puma_tag, fetch(:application)
set :puma_daemonize, false
set :puma_preload_app, false
set :puma_prune_bundler, true
set :puma_init_active_record, true
set :puma_workers, 0
set :puma_bind, %w(tcp://0.0.0.0:9200)
set :puma_start_task, 'systemd:puma:start'

set :init_system, :systemd

set :systemd_sidekiq_role, :sidekiq
set :systemd_sidekiq_instances, -> { [:default, :reports] }

set :app_version, SemVer.find.to_s

before 'deploy:starting', 'sentry:validate_config'
after 'deploy:published', 'sentry:notice_deployment'

set :sentry_organization, ENV['SENTRY_ORGANIZATION']
# set :sentry_api_token, ENV['SENTRY_API_TOKEN']

# after 'deploy:check', 'master_key:check'
# after 'deploy:publishing', 'systemd:puma:reload-or-restart'
# after 'deploy:publishing', 'systemd:sidekiq:reload-or-restart'
# after 'deploy:published', 'bugsnag:release'
