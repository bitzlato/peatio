# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::TransactionCreator do
  include_context 'shared tron'

  describe '#create_transaction!' do
    it 'create TransferContract tx' do
      VCR.use_cassette('tron/create_transfer_contract', record: :once) do
        tx = gateway.create_transaction!(
          from_address: hot_wallet.address,
          to_address: payment_address.address,
          amount: 100,
          blockchain_address: hot_wallet.blockchain_address
        )

        expect(tx).to be_a(Peatio::Transaction)
      end
    end

    it 'create TriggerSmartContract tx' do
      VCR.use_cassette('tron/create_trigger_smart_contract', record: :once) do
        tx = gateway.create_transaction!(
          from_address: hot_wallet.address,
          to_address: payment_address.address,
          amount: 100,
          blockchain_address: hot_wallet.blockchain_address,
          contract_address: usdj_trc20.contract_address
        )

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.contract_address).not_to be nil
      end
    end
  end
end
