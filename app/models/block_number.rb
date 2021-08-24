class BlockNumber < ApplicationRecord
  upsert_keys [:blockchain_id, :number]
  belongs_to :blockchain

  STATUSES = %w(pending processing success error)
  before_validation if: :status? do
    self.status = self.status.to_s
  end
  validates :status, presence: true, inclusion: { in: STATUSES }
end
