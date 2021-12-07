# frozen_string_literal: true

FactoryBot.define do
  factory :blockchain_address do
    transient do
      key { Eth::Key.new }
    end
    address_type { 'ethereum' }
    address { key.address }
    private_key_hex { key.private_hex }
  end
end
