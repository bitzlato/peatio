# encoding: UTF-8
# frozen_string_literal: true

class Beneficiary < ApplicationRecord

  # == Constants ============================================================

  extend Enumerize

  include Vault::EncryptedModel

  vault_lazy_decrypt!

  include AASM
  include AASM::Locking

  STATES_MAPPING = { pending: 0, active: 1, archived: 2, aml_processing: 3, aml_suspicious: 4 }.freeze

  STATES = %i[pending aml_processing aml_suspicious active archived].freeze
  STATES_AVAILABLE_FOR_MEMBER = %i[pending active]

  PIN_LENGTH  = 6
  PIN_RANGE   = 10**5..10**Beneficiary::PIN_LENGTH

  INVALID_ADDRESS_SYMBOLS = /[\<\>\'\,\[\]\}\{\"\)\(\*\&\^\%\$\#\`\~\{\}\@]/.freeze

  # == Attributes ===========================================================

  vault_attribute :data, serialize: :json, default: {}

  # == Extensions ===========================================================

  enumerize :state, in: STATES_MAPPING, scope: true

  aasm column: :state, enum: :states_mapping, whiny_transitions: false do
    state :pending, initial: true
    state :active
    state :aml_processing
    state :aml_suspicious
    state :archived

    event :activate do
      if Peatio::AML.adapter.present?
        transitions from: :pending, to: :aml_processing, guard: :valid_pin?
        after do
          enable! if aml_check!
        end
      else
        transitions from: :pending, to: :active, guard: :valid_pin?
      end
    end

    event :enable do
      transitions from: :aml_processing, to: :active
    end if Peatio::AML.adapter.present?

    event :aml_suspicious do
      transitions from: :aml_processing, to: :aml_suspicious
    end if Peatio::AML.adapter.present?

    event :archive do
      transitions from: %i[pending aml_processing aml_suspicious active], to: :archived
    end
  end

  acts_as_eventable prefix: 'beneficiary', on: %i[create update]

  # == Relationships ========================================================

  belongs_to :currency, required: true
  belongs_to :member, required: true

  # == Validations ==========================================================

  validates :pin, presence: true, numericality: { only_integer: true }

  validates :data, presence: true

  # Validates that data contains address field which is required for coin.
  validate if: ->(b) { b.currency.present? && b.currency.coin? } do
    errors.add(:data, 'address can\'t be blank') if data.blank? || data.symbolize_keys[:address].blank?
  end

  # Validates address field which is required for coin.
  validate if: ->(b) { b.currency.present? && b.currency.coin? } do
    errors.add(:data, 'invlalid address') if data.present? && data.symbolize_keys[:address].present? && data.symbolize_keys[:address].match?(INVALID_ADDRESS_SYMBOLS)
  end

  # Validates that data contains full_name field which is required for fiat.
  validate if: ->(b) { b.currency.present? && b.currency.fiat? } do
    errors.add(:data, 'full_name can\'t be blank') if data.blank? || data.symbolize_keys[:full_name].blank?
  end

  # == Scopes ===============================================================

  scope :available_to_member, -> { with_state(:pending, :active) }

  # == Callbacks ============================================================

  before_validation(on: :create) do
    # Truncate spaces
    data['address'] = data['address'].gsub(/\p{Space}/, '') if data.present? && data['address'].present?

    # Generate Beneficiary Pin
    self.pin ||= self.class.generate_pin
    # Record time when we send event to Event API
    self.sent_at = Time.now
  end

  # == Class Methods ========================================================

  class << self
    def generate_pin
      SecureRandom.rand(Beneficiary::PIN_RANGE)
    end

    # Method used for passing states mapping to AASM.
    def states_mapping
      STATES_MAPPING
    end
  end

  # == Instance Methods =====================================================

  def as_json_for_event_api
    { user:        { uid: member.uid, email: member.email },
      currency:    currency_id,
      name:        name,
      description: description,
      data:        data,
      pin:         pin,
      state:       state,
      sent_at:     sent_at.iso8601,
      created_at:  created_at.iso8601,
      updated_at:  updated_at.iso8601 }
  end

  def aml_check!
    result = Peatio::AML.check!(rid, currency_id, member.uid)
    if result.risk_detected
      b.aml_suspicious!
      return nil
    end
    return nil if result.pending

    true
  end

  def valid_pin?(user_pin)
    case user_pin
    when Integer
      return pin == user_pin
    when String
      return pin == user_pin.to_i
    else
      return false
    end
  end

  def rid
    currency.coin? ? coin_rid : fiat_rid
  end

  def regenerate_pin!
    update(pin: self.class.generate_pin, sent_at: Time.now)
  end

  def masked_account_number
    account_number = data.symbolize_keys[:account_number]

    if data.present? && account_number.present?
      account_number.sub(/(?<=\A.{2})(.*)(?=.{4}\z)/) { |match| '*' * match.length }
    end
  end

  def masked_data
    data.merge(account_number: masked_account_number).compact if data.present?
  end

  private

  def coin_rid
    return unless currency.coin?
    data.symbolize_keys[:address]
  end

  def fiat_rid
    return unless currency.fiat?
    "%s-%s-%08d" % [data.symbolize_keys[:full_name].downcase.split.join('-'), currency_id.downcase, id]
  end
end
