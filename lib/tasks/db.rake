# frozen_string_literal: true

namespace :db do
  desc 'Nullify Peatio encrypted columns'
  task nullify_encrypted_columns: %i[check_protected_environments environment] do
    Beneficiary.update_all(data_encrypted: nil)
    Blockchain.update_all(server_encrypted: nil)
    Engine.update_all(key_encrypted: nil, secret_encrypted: nil, data_encrypted: nil)
    PaymentAddress.update_all(secret_encrypted: nil, details_encrypted: nil)
    Wallet.update_all(settings_encrypted: nil)
  end
end
