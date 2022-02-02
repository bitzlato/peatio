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

  def member_uid=(uid)
    self.member = Member.find_by!(uid: uid)
  end

  def account
    member.get_account(currency_id)
  end
end
