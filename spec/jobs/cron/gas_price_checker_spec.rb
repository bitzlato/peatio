# frozen_string_literal: true

describe Jobs::Cron::GasPriceChecker do
  context 'when transaction price is too high' do
    it 'sets high transaction price time' do
      EthereumGateway::AbstractCommand.any_instance.stubs(:fetch_gas_price).returns 100
      described_class.process(0)
      expect(find(:blockchain, key: 'eth-rinkeby').high_transaction_price_at).not_to eq nil
    end
  end

  context 'when transaction price is low' do
    it 'removes high transaction price time' do
      blockchain = find(:blockchain, key: 'eth-rinkeby')
      blockchain.update!(high_transaction_price_at: 10.minutes.ago)
      EthereumGateway::AbstractCommand.any_instance.stubs(:fetch_gas_price).returns 5
      described_class.process(0)
      expect(find(:blockchain, key: 'eth-rinkeby').high_transaction_price_at).to eq nil
    end
  end
end
