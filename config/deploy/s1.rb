# frozen_string_literal: true

set :rails_env, :staging
set :disallow_pushing, false
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :systemd_daemon_instances, -> { %i[cron_job] }

# Возвращает market-демонов в обычный пул
append :systemd_amqp_daemon_instances, fetch(:market_amqp_daemons)

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons amqp_daemons].freeze,
       ssh_options: { forward_agent: true }
