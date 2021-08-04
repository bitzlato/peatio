# encoding: UTF-8
# frozen_string_literal: true

namespace :influxdb do
  desc 'Creates influx database for current rails environment described in config/influx.yml'
  task create: :environment do
    Peatio::InfluxDB.client.create_database
    puts "Influx database #{Peatio::InfluxDB.client.config.database} has created"
  end
end
