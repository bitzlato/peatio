# frozen_string_literal: true

require 'peatio/app'

Peatio::App.define do |config|
  config.set(:deposit_funds_locked, (!Rails.env.test?).to_s, type: :bool)
  config.set(:manual_deposit_approval, 'false', type: :bool)

  config.set(:official_name, 'bitzlato.com')
  config.set(:official_email, 'support@bitzlato.com')
  config.set(:official_website, 'https://bitzlato.com')
  config.set(:official_signature, '<span>Bitzlato ltd <br>UNIT 617, 6/F, 131-132 CONNAUGHT ROAD WEST SOLO <br>WORKSHOPS <br>HONG KONG</span>')
end
