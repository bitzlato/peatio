# frozen_string_literal: true

class MemberTransfer < ApplicationRecord
  include AASM
  AVAILABLE_SERVICES = %w[p2p].freeze

  belongs_to :member
  belongs_to :currency

  validates :service, presence: true, inclusion: { in: AVAILABLE_SERVICES }
  validates :description, null: false
  validates :key, uniqueness: true, presence: true
  validates :amount, numericality: { other_than: 0 }
  validates :meta, presence: true

  delegate :uid, to: :member, prefix: true

  aasm do
    state :pending, initial: true
    state :finished
    state :errored

    event :finish do
      transitions from: %i[pending], to: :finished
    end

    event :err do
      transitions from: %i[pending], to: :errored
    end
  end

  def member_uid=(uid)
    self.member = Member.find_by!(uid: uid)
  end

  def account
    member.get_account(currency_id)
  end

  def process!
    transaction do
      if amount.positive?
        income!
      else
        outcome!
      end
      finish!
    rescue StandardError => e
      err!
      raise e
    end
  end

  private

  def income!
    account.with_lock do
      account.plus_funds!(amount)

      Operations::Asset.credit!(
        amount: amount,
        currency: currency,
        reference: self
      )

      Operations::Liability.credit!(
        amount: amount,
        currency: currency,
        reference: self,
        member_id: member_id,
        kind: :main
      )
    end
  end

  def outcome!
    account.with_lock do
      account.sub_funds!(-amount)

      Operations::Asset.debit!(
        amount: -amount,
        currency: currency,
        reference: self
      )

      Operations::Liability.debit!(
        amount: -amount,
        currency: currency,
        reference: self,
        member_id: member_id,
        kind: :main
      )
    end
  end
end
