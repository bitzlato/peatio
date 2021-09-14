# frozen_string_literal: true

Dir[Rails.root.join('config/environments/shared/**/*.rb')].each { |p| require p }
