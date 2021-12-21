# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::TransactionFetcher do
  include_context 'shared tron'

  describe '#fetch_transaction' do
    it 'return transaction' do
      tx_id = 'a6850deb302e647f386dce814e272a86919d6d77fde5b44b0db1b6641e51740f'

      VCR.use_cassette('tron/fetch_transaction', record: :once) do
        tx = gateway.fetch_transaction(tx_id)
        expect(tx).to be_a(Peatio::Transaction)
      end
    end
  end
end
