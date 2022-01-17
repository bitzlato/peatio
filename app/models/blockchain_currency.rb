# frozen_string_literal: true

class BlockchainCurrency < ApplicationRecord
  belongs_to :currency
  belongs_to :blockchain
  belongs_to :parent, class_name: 'BlockchainCurrency'

  validate if: :parent_id do
    errors.add :parent_id, 'wrong fiat/crypto nesting' unless currency.fiat? == parent.currency.fiat?
    errors.add :parent_id, 'nesting currency must be token' unless currency.token?
    errors.add :parent_id, 'wrong parent blockchain currency' if parent.parent_id.present?
  end

  after_create do
    link_wallets
  end
  before_validation(if: proc { |blockchain_currency| blockchain_currency.currency.token? }) { self.blockchain ||= parent.blockchain }

  def link_wallets
    return if parent_id.nil?

    # Iterate through active deposit/withdraw wallets
    Wallet.active.where.not(kind: :fee).with_currency(parent.currency_id).each do |wallet|
      # Link parent currency with wallet
      CurrencyWallet.create(currency_id: currency_id, wallet_id: wallet.id)
    end
  end
end
