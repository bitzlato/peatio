class Transaction < ApplicationRecord
  # == Constants ============================================================

  STATUSES = %w[pending succeed].freeze

  alias_attribute :hash, :txid

  # == Attributes ===========================================================

  # == Extensions ===========================================================

  serialize :data, JSON unless Rails.configuration.database_support_json

  # == Relationships ========================================================

  belongs_to :reference, polymorphic: true
  belongs_to :currency
  has_one :blockchain, through: :currency

  # == Validations ==========================================================

  validates :currency, :amount, :from_address, :to_address, :status, presence: true

  validates :status, inclusion: { in: STATUSES }

  # == Scopes ===============================================================

  # == Callbacks ============================================================

  after_initialize :initialize_defaults, if: :new_record?

  # TODO: record expenses for succeed transactions

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  def initialize_defaults
    self.status = :pending if status.blank?
  end

  # TODO Validate txid by blockchain
end
