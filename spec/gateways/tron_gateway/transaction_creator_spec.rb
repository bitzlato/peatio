# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::TransactionCreator, :tron do
  describe '#create_transaction!' do
    it 'create TransferContract tx' do
      VCR.use_cassette('tron/create_transfer_contract', record: :once) do
        tx = tron_gateway.create_transaction!(
          from_address: tron_hot_wallet.address,
          to_address: tron_payment_address.address,
          amount: 100,
          blockchain_address: tron_hot_wallet.blockchain_address
        )

        expect(tx).to be_a(Peatio::Transaction)
      end
    end

    it 'create TriggerSmartContract tx' do
      VCR.use_cassette('tron/create_trigger_smart_contract', record: :once) do
        tx = tron_gateway.create_transaction!(
          from_address: tron_hot_wallet.address,
          to_address: tron_payment_address.address,
          amount: 100,
          blockchain_address: tron_hot_wallet.blockchain_address,
          contract_address: tron_usdj_trc20_blockchain_currency.contract_address
        )

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.contract_address).not_to be nil
      end
    end
  end
end
