# frozen_string_literal: true

class SwapOrder < ApplicationRecord
  extend Enumerize
  attribute :uuid, :uuid if Rails.configuration.database_adapter.downcase != 'PostgreSQL'.downcase

  attr_readonly :member_id,
                :market_id,
                :created_at

  # rubocop:disable Rails/InverseOf
  # rubocop:disable Rails/RedundantForeignKey
  belongs_to :market, foreign_key: :market_id, primary_key: :symbol, optional: false
  belongs_to :member, optional: false
  # rubocop:enable Rails/RedundantForeignKey
  # rubocop:enable Rails/InverseOf

  enum side: { sell: 0, buy: 1 }

  STATES = Order::STATES

  enumerize :state, in: STATES, scope: true

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

  def order
    Order.find_by uuid: uuid
  end
end
