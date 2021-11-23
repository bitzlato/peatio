# frozen_string_literal: true

class SwapOrder < ApplicationRecord
  extend Enumerize
  attribute :uuid, :uuid if Rails.configuration.database_adapter.downcase != 'PostgreSQL'.downcase

  attr_readonly :member_id,
                :market_id,
                :created_at

  has_one :order, foreign_key: :uuid, primary_key: :uuid, dependent: false, inverse_of: false
  belongs_to :market, primary_key: :symbol, optional: false, inverse_of: false
  belongs_to :member, optional: false, inverse_of: false

  enum side: { sell: 0, buy: 1 }

  STATES = Order::STATES

  enumerize :state, in: STATES, scope: true

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :open, -> { with_state(:wait, :pending) }

  validates :price, :volume, presence: true

  validates :price,
            precision: { less_than_or_eq_to: ->(o) { o.market.price_precision } },
            on: :create

  validates :price,
            numericality: { less_than_or_equal_to: ->(order) { order.market.max_price } },
            if: ->(order) { order.market.max_price.nonzero? },
            on: :create

  validates :price,
            numericality: { greater_than_or_equal_to: ->(order) { order.market.min_price } },
            on: :create
end
