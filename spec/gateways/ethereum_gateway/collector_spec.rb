describe ::EthereumGateway::Collector do
  subject { described_class.new(ethereum_client) }

  let(:peatio_transaction) do
    Peatio::Transaction.new(
      currency_id: 'eth',
      amount: 12,
      from_address: '123',
      to_address: '145',
      block_number: 1,
      status: 'pending'
    )
  end
  let(:gas_factor) { 1 }
  let(:native_amount) { 1_000_000 }
  let(:contract_amount) { 1_000_000_000_000_000_000 }
  let(:contract_address) { Faker::Blockchain::Ethereum.address }
  let(:from_address) { Faker::Blockchain::Ethereum.address }
  let(:to_address) { Faker::Blockchain::Ethereum.address }

  it 'collects tokens first' do
    EthereumGateway::TransactionCreator
      .any_instance
      .stubs(:call)
      .with(from_address: from_address,
            to_address: to_address,
            amount: contract_amount,
            secret: nil,
            subtract_fee: false,
            gas_limit: 1,
            gas_factor: gas_factor,
            contract_address: contract_address)
      .once
      .returns(peatio_transaction)
    EthereumGateway::TransactionCreator
      .any_instance
      .stubs(:call)
      .with(from_address: from_address,
            to_address: to_address,
            amount: native_amount,
            secret: nil,
            gas_factor: 1,
            subtract_fee: true,
            gas_limit: 2,
            contract_address: nil)
      .once
      .returns(peatio_transaction)
    subject.send(:call,
                 from_address: from_address,
                 to_address: to_address,
                 gas_limits: { contract_address => 1, nil => 2 },
                 amounts: { contract_address => contract_amount, nil => native_amount },
                 secret: nil)
  end
end
