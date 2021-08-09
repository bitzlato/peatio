module BlockchainGateway
  extend ActiveSupport::Concern
  AVAILABLE_GATEWAYS = [BitzlatoGateway, DummyGateway, BitcoinGateway, EthereumGateway].map(&:to_s)

  included do
    validates :gateway_klass, presence: true, inclusion: { in: AVAILABLE_GATEWAYS }
    delegate :create_address!, to: :gateway
    delegate :implements?, :case_sensitive?, to: :gateway_class

  end

  def gateway_class
    gateway_klass.constantize
  end

  def gateway
    @gateway ||= gateway_class.new(self).freeze
  end
end
