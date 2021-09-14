# frozen_string_literal: true

class Refund < ApplicationRecord
  extend Enumerize
  include AASM

  belongs_to :deposit, required: true

  aasm column: :state, whiny_transitions: false, requires_lock: true do
    state :pending, initial: true
    state :processed
    state :failed

    event :process do
      transitions from: :pending, to: :processed

      after do
        process_refund!
      end
    end

    event :fail do
      transitions from: %i[pending processed], to: :failed
    end
  end

  def process_refund!
    transaction = WalletService.new(Wallet.active_deposit_wallet(deposit.currency.id)).refund!(self)
    deposit.refund! if transaction.present?
  end
end
