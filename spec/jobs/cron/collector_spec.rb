# frozen_string_literal: true

describe Jobs::Cron::Collector do
  let!(:payment_address) { create :payment_address, :eth_address, balances: { eth: 1 } }

  it do
    expect(PaymentAddress.collection_required.count).to eq 1
  end

  it 'collect' do
    EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
    EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns true
    PaymentAddress.any_instance.expects(:collect!)

    expect { described_class.process }.not_to raise_error
  end

  it 'refuels' do
    EthereumGateway.any_instance.stubs(:has_collectable_balances?).returns true
    EthereumGateway.any_instance.stubs(:has_enough_gas_to_collect?).returns false
    PaymentAddress.any_instance.expects(:refuel_gas!)

    expect { described_class.process }.not_to raise_error
  end
end
