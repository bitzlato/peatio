# frozen_string_literal: true

require 'test_prof/recipes/rspec/factory_default'

RSpec.shared_context 'tron', tron: true do
  let!(:tron_hot_wallet) { create_default(:wallet, :trx_hot, name: 'Tron Hot Wallet') }
  let(:tron_blockchain)       { tron_hot_wallet.blockchain }
  let(:tron_gateway)          { TronGateway.new(tron_blockchain) }
  let!(:tron_trx)              { create_default(:currency, :trx, id: :trx) }
  let!(:tron_usdj_trc20)       { create_default(:currency, :'usdj-trc20', id: :'usdj-trc20') }
  let(:tron_fee_blockchain_currency) { tron_blockchain.fee_blockchain_currency }
  let!(:tron_payment_address) do
    tron_deposit_address = 'TLiwXKmPRS8EuBgp35soVwAtuPFE94moxc'
    tron_deposit_private_key = '5c0c887905fcb0821721c17ff9a1c28501c3f96f4d07a4b7160ddb32587a663d'

    create_default(:payment_address, blockchain: tron_blockchain, address: tron_deposit_address).tap do |_pm|
      create_default :blockchain_address, address: tron_deposit_address, private_key_hex: tron_deposit_private_key, address_type: TronGateway.address_type
    end
  end
  let!(:tron_trx_blockchain_currency) do
    options = { bandwidth_limit: 270 }
    create_default(:blockchain_currency, blockchain: tron_blockchain, currency: tron_trx, options: options, withdraw_fee: 0.025)
  end
  let!(:tron_usdj_trc20_blockchain_currency) do
    contract_address = 'TLBaRhANQoJFTqre9Nf1mjuwNWjCJeYqUL'
    options = { bandwidth_limit: 270, energy_limit: 15_000 }
    create_default(:blockchain_currency, blockchain: tron_blockchain, currency: tron_usdj_trc20, withdraw_fee: 0.025,
                                         options: options, parent_id: tron_trx_blockchain_currency.id, contract_address: contract_address, gas_limit: 10_000_000)
  end
end
