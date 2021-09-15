# frozen_string_literal: true

class BlockNumber < ApplicationRecord
  upsert_keys %i[blockchain_id number]
  belongs_to :blockchain

  STATUSES = %w[pending processing success error].freeze
  before_validation if: :status? do
    self.status = status.to_s
  end
  validates :status, presence: true, inclusion: { in: STATUSES }

  def reprocess!
    blockchain.service.process_block number
  end

  def transactions
    blockchain.transactions.where(block_number: number)
  end
end
