class MemberTransfer < ApplicationRecord
  AVAILABLE_SERVICES = %w[p2p]

  belongs_to :member
  belongs_to :currency

  validates :service, presence: true, inclusion: { in: AVAILABLE_SERVICES }
  validates :description, null: false
  validates :key, uniqueness: true, presence: true
  validates :amount, numericality: { other_than: 0 }
  validates :meta, presence: true

  def member_uid
    member.uid
  end

  def member_uid=(uid)
    self.member = Member.find_by!(uid: uid)
  end
end
