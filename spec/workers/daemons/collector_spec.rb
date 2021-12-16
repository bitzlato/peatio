# frozen_string_literal: true

describe Workers::Daemons::Collector do
  it do
    create :payment_address, :eth_address, balances: { eth: 1 }
    expect(PaymentAddress.collection_required.count).to eq 1
  end

  context 'when deposit has enough gas to collect' do
    it 'collects' do
      create :payment_address, :eth_address, balances: { eth: 1 }
      EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
      EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns true
      PaymentAddress.any_instance.expects(:collect!)

      expect { described_class.new.process }.not_to raise_error
    end
  end

  context 'when deposit just received the gas' do
    it 'skips collection' do
      payment_address = create :payment_address, :eth_address, balances: { eth: 1 }, last_transfer_try_at: Time.current, last_transfer_status: Workers::Daemons::Collector::REFUELED_STATUS
      EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
      EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns true
      EthereumGateway.any_instance.expects(:collect!).never
      described_class.new.process
      expect(payment_address.reload.last_transfer_status).not_to include("Event 'collect' cannot transition")
    end
  end

  context 'when deposit received the gas after TRANSACTION_SLEEP_MINUTES' do
    it 'collects' do
      create :payment_address, :eth_address, balances: { eth: 1 }, last_transfer_try_at: PaymentAddress::TRANSACTION_SLEEP_MINUTES.minutes.ago, last_transfer_status: Workers::Daemons::Collector::REFUELED_STATUS
      EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
      EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns true
      EthereumGateway.any_instance.expects(:collect!).once
      described_class.new.process
    end
  end

  it 'refuels' do
    create :payment_address, :eth_address, balances: { eth: 1 }
    EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
    EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns false
    PaymentAddress.any_instance.expects(:refuel_gas!)

    expect { described_class.new.process }.not_to raise_error
  end
end
