# encoding: UTF-8
# frozen_string_literal: true

# Rename to Gateway
#
class Blockchain < ApplicationRecord
  include Vault::EncryptedModel

  vault_lazy_decrypt!

  vault_attribute :server

  has_many :currencies
  has_many :wallets
  has_many :whitelisted_smart_contracts

  validates :key, :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[active disabled] }
  validates :height,
            :min_confirmations,
            numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :server, url: { allow_blank: true }
  validates :client,
    presence: true,
    inclusion: { in: -> (_) { clients.map(&:to_s) } }

  before_create { self.key = self.key.strip.downcase }

  scope :active, -> { where(status: :active) }

  delegate :create_address!, to: :blockchain_api

  class << self
    def clients
      Peatio::Blockchain.registry.adapters.keys
    end
  end

  def explorer=(hash)
    write_attribute(:explorer_address, hash.fetch('address'))
    write_attribute(:explorer_transaction, hash.fetch('transaction'))
  end

  def status
    super&.inquiry
  end

  def active?
    status.active?
  end

  def dummy?
    client == 'dummy'
  end

  def gateway_implements?(method_name)
    return false if blockchain_api.nil?
    blockchain_api.implements?(method_name)
  end

  def blockchain_api
    return if dummy?
    BlockchainService.new(self)
  rescue StandardError => err
    report_exception err
    return
  end

  # The latest block which blockchain worker has processed
  def processed_height
    height + min_confirmations
  end
end
