# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::Collector do
  include_context 'shared tron'

  describe '#collect!' do
    it 'call create_transaction!' do
      VCR.use_cassette('tron/collect', record: :once) do
        gateway.expects(:create_transaction!).times(1)
        gateway.collect!(payment_address)
      end
    end
  end
end
