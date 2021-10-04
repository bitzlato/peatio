# frozen_string_literal: true

module GatewayConcern
  extend ActiveSupport::Concern

  # Actualy `client` attribute name is not inadequate. I prefer gateway_klass
  # But we have to have client attribute to have compatibility admin api and tower

  GATEWAY_PREFIX = 'Gateway'

  # TODO: Move to Settings
  #
  AVAILABLE_GATEWAYS = [
    BitzlatoGateway,
    DummyGateway,
    BitcoinGateway,
    EthereumGateway
  ].map(&:to_s)

  CLIENTS = AVAILABLE_GATEWAYS.map { |g| g.remove(GATEWAY_PREFIX).downcase }

  included do
    validates :client, presence: true, inclusion: { in: CLIENTS }
    delegate :create_address!, to: :gateway

    delegate :normalize_address, :normalize_txid, :valid_address?, :valid_txid?, to: :gateway_class

    def self.clients
      CLIENTS
    end
  end

  def gateway_class
    gateway_klass.constantize
  end

  def gateway
    @gateway ||= gateway_class.new(self).freeze
  end

  def gateway_klass
    client.camelize + GATEWAY_PREFIX
  end

  def gateway_klass=(value)
    return self.client = nil if value.blank?

    self.client = value.to_s.remove(GATEWAY_PREFIX).downcase
  end
end
