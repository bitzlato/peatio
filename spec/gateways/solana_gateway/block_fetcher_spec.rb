# frozen_string_literal: true

require './spec/gateways/shared_solana'

describe ::SolanaGateway::BlockFetcher, :solana do
  describe '#fetch_block_transactions' do
    let(:token_transfer_blocknum) { 119_613_633 }
    let(:smart_contract_trigger_blocknum) { 120_100_226 }
    let(:associated_account_creation) { 120_143_927 }
    let(:associated_account_address) { 'HPj4NesF3a8fvpq7mEoasMCoq4vmLSVLrz6ikwiwmkqM' }
    let(:account_adddress_multi_account) { 'BgQmWECccqojwgBUpcHgRKUGiS2Xff1b7mk8Cxbv5yqu' }

    it 'return token transfer' do
      VCR.use_cassette('solana/fetch_block_transactions_token_transfer', record: :once) do
        transactions = solana_gateway.fetch_block_transactions(token_transfer_blocknum)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(1)
        tx = transactions.first

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.amount).to be_a(Money)
        expect(tx.amount.base_units).to eq(1250000000)
        expect(tx.amount.currency.id.to_s).to eq(solana_spl_blockchain_currency.id.to_s)
        expect(tx.fee).to be_a(Money)
        expect(tx.fee.currency.id.to_s).to eq(solana_blockchain_currency.id.to_s)
        expect(tx.fee.base_units).to eq(10000)
        expect(tx.from_addresses).to eq([solana_contract_payment_address])
        expect(tx.to_address).to eq(solana_spl_hot_wallet.address)
        expect(tx.contract_address).to eq(solana_spl_blockchain_currency.contract_address)
        expect(tx.fee_payer_address).to eq(solana_hot_wallet.address)
      end
    end

    it 'return native transfer' do
      VCR.use_cassette('solana/fetch_block_transactions_native_transfer', record: :once) do
        transactions = solana_gateway.fetch_block_transactions(smart_contract_trigger_blocknum)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(1)
        tx = transactions.first

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.amount).to be_a(Money)
        expect(tx.amount.base_units).to eq(330000000)
        expect(tx.amount.currency.id.to_s).to eq(solana_blockchain_currency.id.to_s)
        expect(tx.fee).to be_a(Money)
        expect(tx.fee.currency.id.to_s).to eq(solana_blockchain_currency.id.to_s)
        expect(tx.fee.base_units).to eq(5000)
        expect(tx.to_address).to eq(solana_payment_address.address)
        expect(tx.contract_address).to eq(nil)
      end
    end

    it 'return native transfer' do
      VCR.use_cassette('solana/fetch_block_transactions_associated_account_creation', record: :once) do
        create(:payment_address, address: associated_account_address)
        transactions = solana_gateway.fetch_block_transactions(associated_account_creation)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(1)
        tx = transactions.first

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.amount).to be_a(Money)
        expect(tx.amount.base_units).to eq(2039280)
        expect(tx.amount.currency.id.to_s).to eq(solana_blockchain_currency.id.to_s)
        expect(tx.fee).to be_a(Money)
        expect(tx.fee.currency.id.to_s).to eq(solana_blockchain_currency.id.to_s)
        expect(tx.fee.base_units).to eq(5000)
        expect(tx.from_addresses).to eq([solana_hot_wallet.address])
        expect(tx.to_address).to eq(associated_account_address)
        expect(tx.fee_payer_address).to eq(solana_hot_wallet.address)
      end
    end

    it 'return multiple transactions for multiinstruction transaction' do
      VCR.use_cassette('solana/fetch_block_transactions_multiple', record: :once) do
        create(:payment_address, blockchain: solana_blockchain, address: account_adddress_multi_account)
        transactions = solana_gateway.fetch_block_transactions(120157136)
        expect(transactions).to be_a(Array)
        expect(transactions.size).to eq(2)
        tx = transactions.first
        expect(tx.amount.base_units).to eq(2039280)
        expect(tx.to_address).to eq(account_adddress_multi_account)

        tx = transactions.last
        expect(tx.amount.base_units).to eq(147000000)
        expect(tx.to_address).to eq(account_adddress_multi_account)
        expect(transactions.map(&:instruction_id)).to eq([0,1])
      end
    end
  end
end
