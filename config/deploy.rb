# frozen_string_literal: true

lock '3.16'

set :user, 'app'
set :application, 'peatio'

set :roles, %w[app db].freeze

set :repo_url, ENV.fetch('DEPLOY_REPO', `git remote -v | grep origin | head -1 | awk  '{ print $2 }'`.chomp) if ENV['USE_LOCAL_REPO'].nil?
set :keep_releases, 10

set :linked_files, %w[.env .env.daemons]
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets]
set :config_files, fetch(:linked_files)

set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:application)}" }

set :disallow_pushing, true

set :bugsnag_api_key, ENV.fetch('BUGSNAG_API_KEY')

default_branch = 'master'
current_branch = `git rev-parse --abbrev-ref HEAD`.chomp

if ENV.key? 'BRANCH'
  set :branch, ENV.fetch('BRANCH')
elsif default_branch == current_branch
  set :branch, default_branch
else
  ask(:branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp })
end

set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip

set :conditionally_migrate, true # Only attempt migration if db/migrate changed - not related to Webpacker, but a nice thing

set :db_dump_extra_opts, '--force'
set :db_local_clean, false
set :db_remote_clean, true

set :app_version, SemVer.find.to_s
set :current_version, `git rev-parse HEAD`.strip

if Gem.loaded_specs.key?('capistrano-sentry')
  set :sentry_organization, ENV['SENTRY_ORGANIZATION']
  set :sentry_release_version, -> { [fetch(:app_version), fetch(:current_version)].compact.join('-') }
  before 'deploy:starting', 'sentry:validate_config'
  after 'deploy:published', 'sentry:notice_deployment'
end

set :puma_tag, fetch(:application)
set :puma_start_task, 'systemd:puma:start'
set :puma_init_active_record, true

set :assets_roles, []

set :init_system, :systemd

set :systemd_daemon_role, :daemons
set :systemd_daemon_instances, -> { %i[cron_job] }

# Restricted daemons list for stages
set :systemd_amqp_daemon_role, :amqp_daemons
set :systemd_market_amqp_daemon_role, :market_amqp_daemons

# TODO: На стейджах НЕ запускать deposit_coin_address, withdraw_coin, deposit_intention
#
set :systemd_amqp_daemon_instances,
    lambda {
      %i[
        balances_updating
        cancel_member_orders
        create_order
        deposit_coin_address
        deposit_intention
        influx_writer
        trade_completed
        withdraw_coin
      ]
    }

# set :market_amqp_daemons, %w[order_processor matching trade_executor]
set :market_amqp_daemons, %w[order_processor]

set :systemd_market_amqp_daemon_instances, lambda {
  (fetch(:markets) || raise('No :markets settings defined'))
    .map { |market| fetch(:market_amqp_daemons).map { |worker| worker + ':' + market } }.flatten
}

after 'deploy:publishing', 'systemd:puma:reload-or-restart'
after 'deploy:publishing', 'systemd:daemon:reload-or-restart'
after 'deploy:publishing', 'systemd:amqp_daemon:reload-or-restart'
after 'deploy:publishing', 'systemd:market_amqp_daemon:reload-or-restart'

if defined? Slackistrano
  Rake::Task['deploy:starting'].prerequisites.delete('slack:deploy:starting')
  set :slackistrano,
      klass: Slackistrano::CustomMessaging,
      channel: ENV['SLACKISTRANO_CHANNEL'],
      webhook: ENV['SLACKISTRANO_WEBHOOK']

  # best when 75px by 75px.
  set :slackistrano_thumb_url, 'https://bitzlato.com/wp-content/uploads/2020/12/logo.svg'
  set :slackistrano_footer_icon, 'https://github.githubassets.com/images/modules/logos_page/Octocat.png'
end

# Removed rake, bundle, gem
# Added rails.
# rake has its own dotenv requirement in Rakefile
set :dotenv_hook_commands, %w[rake rails ruby]

Capistrano::DSL.stages.each do |stage|
  after stage, 'dotenv:hook'
end

namespace :systemd do
  desc 'Statuses of systemd units on every servers'
  task :statuses do
    on roles(:all) do
      execute 'systemctl --user status'
    end
  end
end
