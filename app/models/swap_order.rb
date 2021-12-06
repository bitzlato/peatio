# frozen_string_literal: true

class SwapOrder < ApplicationRecord
  extend Enumerize

  attr_readonly :member_id,
                :market_id,
                :created_at

  belongs_to :from_currency, class_name: 'Currency', foreign_key: :from_unit, inverse_of: false
  belongs_to :to_currency, class_name: 'Currency', foreign_key: :to_unit, inverse_of: false
  belongs_to :request_currency, class_name: 'Currency', foreign_key: :request_unit, inverse_of: false
  belongs_to :order, dependent: false, inverse_of: false
  belongs_to :market, primary_key: :symbol, optional: false, inverse_of: false
  belongs_to :member, optional: false, inverse_of: :swap_orders

  STATES = { pending: 0, wait: 100, done: 200, cancel: -100 }.freeze
  enumerize :state, in: STATES, scope: true

  scope :open, -> { with_state(:wait) }
  scope :daily, -> { where(created_at: DateTime.current.all_day) }
  scope :weekly, -> { where(created_at: DateTime.current.all_week) }
  scope :for_member, ->(member) { where(member: member) }

  # validate :price, :volume, presence: true

  def self.daily_amount_for(member)
    SwapOrder.daily
             .with_state(:pending, :wait)
             .for_member(member)
             .joins(:request_currency)
             .sum('currencies.price * request_volume').to_d
  end

  def self.weekly_amount_for(member)
    SwapOrder.weekly
             .with_state(:pending, :wait)
             .for_member(member)
             .joins(:request_currency)
             .sum('currencies.price * request_volume').to_d
  end
end
