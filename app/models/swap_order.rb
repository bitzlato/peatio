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
  belongs_to :member, optional: false, inverse_of: :swap_orders
  belongs_to :unified_currency, class_name: 'Currency', foreign_key: :unified_unit, optional: false, inverse_of: false

  STATES = { pending: 0, wait: 100, done: 200, cancel: -100 }.freeze
  enumerize :state, in: STATES, scope: true

  scope :open, -> { with_state(:wait) }
  scope :daily, -> { where(created_at: DateTime.current.all_day) }
  scope :weekly, -> { where(created_at: DateTime.current.all_week) }
  scope :for_member, ->(member) { where(member: member) }

  validates :price, :volume, presence: true
  validates :unified_price, :unified_total_amount, presence: true

  def self.daily_unified_total_amount_for(member)
    SwapOrder.daily
             .with_state(:pending, :wait)
             .for_member(member)
             .sum(:unified_total_amount).to_d
  end

  def self.weekly_unified_total_amount_for(member)
    SwapOrder.weekly
             .with_state(:pending, :wait)
             .for_member(member)
             .sum(:unified_total_amount).to_d
  end
end
