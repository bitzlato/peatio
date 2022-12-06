# frozen_string_literal: true

require 'securerandom'

class Member < ApplicationRecord
  class NotActiveError < StandardError; end

  has_many :orders
  has_many :swap_orders, inverse_of: :member
  has_many :accounts
  has_many :stats_member_pnl
  has_many :payment_addresses
  has_many :withdraws, -> { order(id: :desc) }
  has_many :deposits, -> { order(id: :desc) }
  has_many :beneficiaries, -> { order(id: :desc) }

  belongs_to :member_group, primary_key: :key, foreign_key: :group

  scope :enabled, -> { where(state: 'active') }

  before_validation :downcase_email

  validates :uid, length: { maximum: 32 }
  validates :email, allow_blank: true, uniqueness: true, email: true
  validates :level, numericality: { greater_than_or_equal_to: 0 }
  validates :role, inclusion: { in: ::Ability.roles }

  before_create { self.group = group.strip.downcase }
  after_create { AirdropService.new(self).perform if ENV.true? 'AUTO_AIRDROP_FOR_NEW_MEMBERS' }

  delegate :open_orders_limit, :rates_limits, to: :mandatory_member_group

  class << self
    def groups
      (TradingFee.distinct.pluck(:group) + MemberGroup.distinct.pluck(:key)).uniq.sort
    end
  end

  def mandatory_member_group
    member_group || MemberGroup.default
  end

  def trades
    Trade.where('maker_id = ? OR taker_id = ?', id, id)
  end

  def role
    super&.inquiry
  end

  def admin?
    role == 'admin'
  end

  def get_account(model_or_id_or_code)
    case model_or_id_or_code
    when String, Symbol
      accounts.find_or_create_by!(currency_id: model_or_id_or_code)
    when Currency
      accounts.find_or_create_by!(currency: model_or_id_or_code)
    end
  # Thread Safe Account creation
  rescue ActiveRecord::RecordNotUnique
    case model_or_id_or_code
    when String, Symbol
      accounts.find_by(currency_id: model_or_id_or_code)
    when Currency
      accounts.find_by(currency: model_or_id_or_code)
    end
  end

  # @deprecated
  def touch_accounts
    Currency.find_each do |currency|
      next if accounts.exists?(currency: currency)

      accounts.create!(currency: currency)
    end
  end

  def withdraw_disabled?
    withdraw_disabled_at.present?
  end

  def withdraw_enabled?
    !withdraw_disabled?
  end

  def balance_for(currency:, kind:)
    account_code = Operations::Account.find_by(
      type: :liability,
      kind: kind,
      currency_type: currency.type
    ).code
    liabilities = Operations::Liability.where(member_id: id, currency: currency, code: account_code)
    liabilities.sum('credit - debit')
  end

  def legacy_balance_for(currency:, kind:)
    case kind.to_sym
    when :main
      get_account(currency).balance
    when :locked
      get_account(currency).locked
    else
      raise Operations::Exception, "Account for #{options} doesn't exists."
    end
  end

  def revert_trading_activity!(trades)
    trades.each(&:revert_trade!)
  end

  def payment_address(blockchain)
    raise 'no blockchain' if blockchain.nil?
    raise "We must not build payment address for invoicing blockchains (#{blockchain.key}) member_id=#{id}" if blockchain.enable_invoice?

    pa = PaymentAddress.active.find_by(member: self, blockchain: blockchain, parent: nil)

    if pa.blank?
      pa = payment_addresses.create!(blockchain: blockchain)
    elsif pa.address.blank?
      pa.enqueue_address_generation
    end

    pa
  end

  # Attempts to create additional deposit address for account.
  def payment_address!(blockchain)
    raise "We must not build payment address for invoicing blockchains member_id=#{id}" if blockchain.enable_invoice?

    pa = PaymentAddress.active.find_by(member: self, blockchain: blockchain)

    # The address generation process is in progress.
    if pa.present? && pa.address.blank?
      pa
    else
      # allows user to have multiple addresses
      pa = payment_addresses.create!(blockchain: blockchain)
    end
    pa
  end

  private

  def downcase_email
    self.email = email.try(:downcase)
  end

  class << self
    def uid(member_id)
      Member.find_by(id: member_id)&.uid
    end

    def find_by_username_or_uid(uid_or_username)
      if Member.find_by(uid: uid_or_username).present?
        Member.find_by(uid: uid_or_username)
      elsif Member.find_by(username: uid_or_username).present?
        Member.find_by(username: uid_or_username)
      end
    end

    # Create Member object from payload
    # == Example payload
    # {
    #   :iss=>"barong",
    #   :sub=>"session",
    #   :aud=>["peatio"],
    #   :email=>"admin@barong.io",
    #   :username=>"barong",
    #   :uid=>"U123456789",
    #   :role=>"admin",
    #   :state=>"active",
    #   :level=>"3",
    #   :iat=>1540824073,
    #   :exp=>1540824078,
    #   :jti=>"4f3226e554fa513a"
    # }

    def from_payload(p)
      params = filter_payload(p)
      validate_payload(params)
      member = Member.find_or_create_by(uid: p[:uid]) do |m|
        m.email = params[:email]
        m.username = params[:username]
        m.role = params[:role]
        m.state = params[:state]
        m.level = params[:level]
      end
      member.assign_attributes(params)
      member.save! if member.changed?
      member
    end

    # Filter and validate payload params
    def filter_payload(payload)
      payload.slice(:email, :username, :uid, :role, :state, :level)
    end

    def validate_payload(p)
      fetch_email(p)
      p.fetch(:uid).tap { |uid| raise(Peatio::Auth::Error, 'UID is blank.') if uid.blank? }
      p.fetch(:role).tap { |role| raise(Peatio::Auth::Error, 'Role is blank.') if role.blank? }
      p.fetch(:level).tap { |level| raise(Peatio::Auth::Error, 'Level is blank.') if level.blank? }
      p.fetch(:state).tap do |state|
        raise(Peatio::Auth::Error, 'State is blank.') if state.blank?
        raise(NotActiveError, "Member #{p[:uid]} is not active.") unless state == 'active'
      end
    end

    def fetch_email(payload)
      payload[:email].to_s.tap do |email|
        raise(Peatio::Auth::Error, 'E-Mail is invalid.') if email.present? && !EmailValidator.valid?(email)
      end
    end

    def search(field: nil, term: nil)
      term = "%#{term}%"
      case field
      when 'email'
        where('email LIKE ?', term)
      when 'uid'
        where('uid LIKE ?', term)
      when 'wallet_address'
        joins(:payment_addresses).where('payment_addresses.address LIKE ?', term)
      else
        all
      end.order(:id).reverse_order
    end
  end
end
