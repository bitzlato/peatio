# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::Collector, :tron do
  describe '#collect!' do
    it 'call create_transaction!' do
      VCR.use_cassette('tron/collect', record: :once) do
        tron_gateway.expects(:create_transaction!).times(1)
        tron_gateway.collect!(tron_payment_address)
      end
    end
  end
end
