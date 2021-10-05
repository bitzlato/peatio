# frozen_string_literal: true

set :rails_env, :sandbox
set :disallow_pushing, false
set :application, -> { 'peatio-sandbox' }
set :deploy_to, -> { "/home/#{fetch(:user)}/#{fetch(:stage)}/#{fetch(:application)}" }

set :systemd_daemon_instances, -> { %i[cron_job blockchain] }

server '217.182.138.99',
       user: fetch(:user),
       port: '22',
       roles: %w[app db daemons].freeze,
       ssh_options: { forward_agent: true }
