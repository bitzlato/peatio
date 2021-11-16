# frozen_string_literal: true

require 'csv'

class Order < ApplicationRecord
  extend Enumerize

  attribute :uuid, :uuid if Rails.configuration.database_adapter.downcase != 'PostgreSQL'.downcase

  attr_readonly :member_id,
                :bid,
                :ask,
                :market_id,
                :ord_type,
                :origin_volume,
                :origin_locked,
                :created_at

  # Error is raised in case market doesn't have enough volume to fulfill the Order.
  InsufficientMarketLiquidity = Class.new(StandardError)

  PENDING = 'pending'
  WAIT    = 'wait'
  DONE    = 'done'
  CANCEL  = 'cancel'
  REJECT  = 'reject'

  STATES = { pending: 0, wait: 100, done: 200, cancel: -100, reject: -200 }.freeze

  TYPES = %w[market limit].freeze

  THIRD_PARTY_ORDER_ACTION_TYPE = {
    submit_single: 0,
    cancel_single: 3,
    cancel_bulk: 4
  }.freeze

  belongs_to :market, ->(order) { where(type: order.market_type) }, foreign_key: :market_id, primary_key: :symbol, optional: false
  belongs_to :member, optional: false
  belongs_to :ask_currency, class_name: 'Currency', foreign_key: :ask
  belongs_to :bid_currency, class_name: 'Currency', foreign_key: :bid

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
  scope :open, -> { with_state(:wait, :pending) }
  scope :with_market, ->(market) { where(market_id: market.is_a?(Market) ? market.symbol : market) }
  scope :spot, -> { where(market_type: 'spot') }
  scope :qe, -> { where(market_type: 'qe') }

  validates :market_type, presence: true, inclusion: { in: ->(_o) { Market::TYPES } }

  validates :ord_type, :volume, :origin_volume, :locked, :origin_locked, presence: true
  validates :price, numericality: { greater_than: 0 }, if: ->(order) { order.ord_type == 'limit' }

  validates :origin_volume,
            numericality: { greater_than: 0, greater_than_or_equal_to: ->(order) { order.market.min_amount } },
            on: :create

  validates :origin_volume, precision: { less_than_or_eq_to: ->(o) { o.market.amount_precision } },
                            if: ->(o) { o.origin_volume.present? }, on: :create

  validate  :market_order_validations, if: ->(order) { order.ord_type == 'market' }

  validates :price, presence: true, if: :is_limit_order?

  validates :price, precision: { less_than_or_eq_to: ->(o) { o.market.price_precision } },
                    if: ->(o) { o.price.present? }, on: :create

  validates :price,
            numericality: { less_than_or_equal_to: ->(order) { order.market.max_price } },
            if: ->(order) { order.is_limit_order? && order.market.max_price.nonzero? },
            on: :create

  validates :price,
            numericality: { greater_than_or_equal_to: ->(order) { order.market.min_price } },
            if: :is_limit_order?, on: :create

  enumerize :state, in: STATES, scope: true

  ransacker :state, formatter: proc { |v| STATES[v.to_sym] } do |parent|
    parent.table[:state]
  end

  after_commit :trigger_private_event

  before_destroy do
    raise 'Only rejected or canceled orders can be destroyed' unless %w[cancel reject].include? state
    raise 'Destroyable order must not have trades' if trades_count.positive?
  end

  after_destroy do
    Operations::Liability.where(reference: self).delete_all
  end

  before_create unless: -> { Rails.env.test? } do
    if member_balance < locked
      raise(
        ::Account::AccountError,
        "member_balance > locked = #{member_balance} > #{locked}"
      )
    end
  end

  before_create do
    raise 'Orders disabled' if ENV.true?('DISABLE_CREATE_ORDERS')
  end

  after_commit on: :update do
    next unless ord_type == 'limit'

    event = case state
            when 'cancel' then 'order_canceled'
            when 'done'   then 'order_completed'
            else 'order_updated'
            end

    Serializers::EventAPI.const_get(event.camelize).call(self).tap do |payload|
      EventAPI.notify ['market', market_id, event].join('.'), payload
    end
  end

  class << self
    def trigger_bulk_cancel_third_party(engine_driver, filters = {})
      AMQP::Queue.publish(engine_driver,
                          data: filters,
                          type: THIRD_PARTY_ORDER_ACTION_TYPE[:cancel_bulk])
    end

    def to_csv
      attributes = %w[id market_id market_type ord_type side price volume origin_volume avg_price trades_count state created_at updated_at]

      CSV.generate(headers: true) do |csv|
        csv << attributes

        all.each do |order|
          data = attributes[0...-2].map { |attr| order.send(attr) }
          data += attributes[-2..].map { |attr| order.send(attr).iso8601 }
          csv << data
        end
      end
    end
  end

  def trigger_third_party_creation
    self.uuid ||= UUID.generate
    self.created_at ||= Time.now

    AMQP::Queue.publish(market.engine.driver, data: as_json_for_third_party, type: THIRD_PARTY_ORDER_ACTION_TYPE[:submit_single])
  end

  def trigger_cancellation
    with_lock do
      return if canceling_at?
      return unless [::Order::PENDING, ::Order::WAIT].include? state
      # TODO: Если событие потерялось, то заявка никогда не отменится
      touch :canceling_at
    end
    market.engine.peatio_engine? ? trigger_internal_cancellation : trigger_third_party_cancellation
  end

  def trigger_internal_cancellation
    # TODO: Зачем для отмены передавать все параметры? Достаточно только ID. Осталное можно подгрузить уже в order_processor
    if Peatio::App.config.market_specific_workers
      AMQP::Queue.enqueue(:matching,
                          { action: 'cancel', order: to_matching_attributes },
                          {},
                          market_id)
    else
      AMQP::Queue.enqueue(:matching, { action: 'cancel', order: to_matching_attributes })
    end
  end

  def trigger_third_party_cancellation
    AMQP::Queue.publish(market.engine.driver,
                        data: as_json_for_third_party,
                        type: THIRD_PARTY_ORDER_ACTION_TYPE[:cancel_single])
  end

  def trades
    Trade.where('market_type = ? AND (maker_order_id = ? OR taker_order_id = ?)', market_type, id, id)
  end

  def funds_used
    origin_locked - locked
  end

  def trigger_private_event
    ::AMQP::Queue.enqueue_event('private', member&.uid, 'order', for_notify)
  end

  def side
    self.class.name.underscore[-3, 3] == 'ask' ? 'sell' : 'buy'
  end

  # @deprecated Please use {#side} instead
  def kind
    self.class.name.underscore[-3, 3]
  end

  # @deprecated Please use {#created_at} instead
  def at
    created_at.to_i
  end

  def for_notify
    {
      id: id,
      market: market_id,
      kind: kind,
      side: side,
      ord_type: ord_type,
      price: price&.to_s('F'),
      avg_price: avg_price&.to_s('F'),
      state: state,
      origin_volume: origin_volume.to_s('F'),
      remaining_volume: volume.to_s('F'),
      executed_volume: (origin_volume - volume).to_s('F'),
      at: at,
      created_at: created_at.to_i,
      updated_at: updated_at.to_i,
      trades_count: trades_count,
      uuid: uuid
    }
  end

  def to_matching_attributes
    { id: id,
      market: market_id,
      type: type[-3, 3].downcase.to_sym,
      ord_type: ord_type,
      volume: volume,
      price: price,
      locked: locked,
      timestamp: created_at.to_i }
  end

  def as_json_for_events_processor
    {
      id: id,
      member_id: member_id,
      member_uid: member.uid,
      ask: ask,
      bid: bid,
      type: type,
      ord_type: ord_type,
      price: price,
      volume: volume,
      origin_volume: origin_volume,
      market_id: market_id,
      maker_fee: maker_fee,
      taker_fee: taker_fee,
      locked: locked,
      state: read_attribute_before_type_cast(:state)
    }
  end

  def as_json_for_third_party
    {
      uuid: uuid,
      market_id: market_id,
      member_uid: member.uid,
      origin_volume: origin_volume,
      volume: volume,
      price: price,
      side: type,
      type: ord_type,
      created_at: created_at.to_i
    }
  end

  # @deprecated
  def round_amount_and_price
    self.price = market.round_price(price.to_d) if price

    if volume
      self.volume = market.round_amount(volume.to_d)
      self.origin_volume = origin_volume.present? ? market.round_amount(origin_volume.to_d) : volume
    end
  end

  def record_submit_operations!
    transaction do
      # Debit main fiat/crypto Liability account.
      # Credit locked fiat/crypto Liability account.
      Operations::Liability.transfer!(
        amount: locked,
        currency: currency,
        reference: self,
        from_kind: :main,
        to_kind: :locked,
        member_id: member_id
      )
    end
  end

  def record_cancel_operations!
    transaction do
      # Debit locked fiat/crypto Liability account.
      # Credit main fiat/crypto Liability account.
      Operations::Liability.transfer!(
        amount: locked,
        currency: currency,
        reference: self,
        from_kind: :locked,
        to_kind: :main,
        member_id: member_id
      )
    end
  end

  def is_limit_order?
    ord_type == 'limit'
  end

  def member_balance
    member.get_account(currency).balance
  end

  private

  def market_order_validations
    errors.add(:price, 'must not be present') if price.present?
  end
end

# == Schema Information
# Schema version: 20201125134745
#
# Table name: orders
#
#  id             :integer          not null, primary key
#  uuid           :binary(16)       not null
#  remote_id      :string(255)
#  bid            :string(10)       not null
#  ask            :string(10)       not null
#  market_id      :string(20)       not null
#  price          :decimal(32, 16)
#  volume         :decimal(32, 16)  not null
#  origin_volume  :decimal(32, 16)  not null
#  maker_fee      :decimal(17, 16)  default(0.0), not null
#  taker_fee      :decimal(17, 16)  default(0.0), not null
#  state          :integer          not null
#  type           :string(8)        not null
#  member_id      :integer          not null
#  ord_type       :string(30)       not null
#  locked         :decimal(32, 16)  default(0.0), not null
#  origin_locked  :decimal(32, 16)  default(0.0), not null
#  funds_received :decimal(32, 16)  default(0.0)
#  trades_count   :integer          default(0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_orders_on_member_id                     (member_id)
#  index_orders_on_state                         (state)
#  index_orders_on_type_and_market_id            (type,market_id)
#  index_orders_on_type_and_member_id            (type,member_id)
#  index_orders_on_type_and_state_and_market_id  (type,state,market_id)
#  index_orders_on_type_and_state_and_member_id  (type,state,member_id)
#  index_orders_on_updated_at                    (updated_at)
#  index_orders_on_uuid                          (uuid) UNIQUE
#
