# frozen_string_literal: true

class MemberGroup < ApplicationRecord
  DEFAULT_RATES_LIMITS = { 'second' => 10, 'minut' => 100 }.freeze
  DEFAULT_OPEN_ORDERS_LIMIT = 3

  validates :key, presence: true, uniqueness: true

  before_create do
    self.rates_limits ||= DEFAULT_RATES_LIMITS
    self.open_orders_limit ||= DEFAULT_OPEN_ORDERS_LIMIT
  end

  def self.default
    new(rates_limits: DEFAULT_RATES_LIMITS, open_orders_limit: DEFAULT_OPEN_ORDERS_LIMIT).freeze
  end
end
