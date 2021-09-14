# frozen_string_literal: true

Dir[Rails.root.join('config/environments/shared/**/*.rb')].sort.each { |p| require p }
