# frozen_string_literal: true

require 'peatio/app'

Peatio::App.define do |config|
  config.set(:deposit_funds_locked, 'true', type: :bool)
  config.set(:manual_deposit_approval, 'false', type: :bool)
end
