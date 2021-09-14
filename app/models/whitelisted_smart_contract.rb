# frozen_string_literal: true

class WhitelistedSmartContract < ApplicationRecord
  # == Constants ============================================================

  STATES = %w[active disabled].freeze

  # == Relationships ========================================================

  belongs_to :blockchain, touch: true, optional: false

  # == Validations ==========================================================

  validates :address, presence: true, uniqueness: { scope: :blockchain_id }
  validates :state, inclusion: { in: STATES }

  # == Scopes ===============================================================

  scope :active, -> { where(state: :active) }
  scope :ordered, -> { order(kind: :asc) }

  delegate :key, to: :blockchain, prefix: true
end
