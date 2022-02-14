# frozen_string_literal: true

class InternalTransfer < ApplicationRecord
  # == Constants ============================================================
  # == Attributes ===========================================================
  # == Extensions ===========================================================

  acts_as_eventable prefix: 'internal_transfer', on: %i[create update]

  # == Relationships ========================================================

  belongs_to :currency
  belongs_to :sender, class_name: :Member, optional: false
  belongs_to :receiver, class_name: :Member, optional: false

  # == Validations ==========================================================

  validates :currency, :amount, :sender, :receiver, :state, presence: true

  validate if: :legacy_currency_transfer? do
    raise 'Sender and Receiver must be equal for legacy_currency_transfer' unless sender == receiver
  end

  validate unless: :legacy_currency_transfer? do
    raise 'Transfers for same Sender and Receiver available only for legacy currencies' if sender == receiver
  end

  # == Scopes ===============================================================
  # == Callbacks ============================================================

  before_commit on: :create do
    InternalTransfer.transaction do
      liabilities = [
        Operations::Liability.debit!(amount: amount, currency: debit_currency, reference: self, member_id: sender_id),
        Operations::Liability.credit!(amount: amount, currency: credit_currency, reference: self, member_id: receiver_id)
      ]
      liabilities.each { |l| Operations.update_legacy_balance(l) }
    end
  end

  # == Class Methods ========================================================
  # == Instance Methods =====================================================

  enum state: { completed: 1 }

  def direction(user)
    user == sender ? 'out' : 'in'
  end

  def debit_currency
    currency
  end

  def credit_currency
    legacy_currency_transfer? ? currency.token_currency : currency
  end

  def legacy_currency_transfer?
    currency.legacy?
  end
end

# == Schema Information
# Schema version: 20210120133912
#
# Table name: internal_transfers
#
#  id          :bigint           not null, primary key
#  currency_id :string(255)      not null
#  amount      :decimal(32, 16)  not null
#  sender_id   :bigint           not null
#  receiver_id :bigint           not null
#  state       :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
