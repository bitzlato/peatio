# frozen_string_literal: true

class SwapOrder < ApplicationRecord
  extend Enumerize

  attr_readonly :member_id,
                :market_id,
                :created_at

  belongs_to :from_currency, class_name: 'Currency', foreign_key: :from_unit, inverse_of: false
  belongs_to :to_currency, class_name: 'Currency', foreign_key: :to_unit, inverse_of: false
  belongs_to :order, dependent: false, inverse_of: false
  belongs_to :market, primary_key: :symbol, optional: false, inverse_of: false
  belongs_to :member, optional: false, inverse_of: false

  STATES = { pending: 0, wait: 100, done: 200, cancel: -100 }.freeze
  enumerize :state, in: STATES, scope: true

  scope :open, -> { with_state(:wait) }

  validates :price, :volume, presence: true
end
