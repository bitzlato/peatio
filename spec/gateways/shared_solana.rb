# frozen_string_literal: true

RSpec.shared_context 'solana', solana: true do
  let!(:sol)                  { create(:currency, :sol, id: :sol, min_collection_amount: 0.02) }
  let!(:sol_spl)              { create(:currency, :'sol_spl', id: :'sol_spl', min_collection_amount: 0.02) }

  let!(:solana_hot_wallet)     { create(:wallet, :sol_hot, name: 'Solana Hot Wallet') }
  let!(:solana_spl_hot_wallet)     { create(:wallet, :sol_spl_hot, name: 'Solana SPL Hot Wallet') }
  let(:solana_blockchain)       { solana_hot_wallet.blockchain }
  let(:solana_gateway)          { SolanaGateway.new(solana_blockchain) }
  let(:solana_contract_payment_address) { 'Fkuy7uE1LwbrY13jft6F74YYfT8Qyzk5JLFnuY9u1Jkt' }

  # let(:solana_fee_blockchain_currency) { solana_blockchain.fee_blockchain_currency }
  let!(:solana_payment_address) do
    solana_deposit_address = '5EaMQFYH31VjFUmN85tX9YbuX89dW7vVSe221GDZ8Z6f'
    solana_deposit_private_key = 'cc3c7f7b9277befdf2b61635a5b3a89d4d7eba08f336bbf629afcf084f0f2709'

    create(:payment_address, blockchain: solana_blockchain, address: solana_deposit_address).tap do |_pm|
      create :blockchain_address, address: solana_deposit_address, private_key_hex: solana_deposit_private_key, address_type: 'solana'
    end
  end

  let!(:solana_blockchain_currency) do
    create(:blockchain_currency, blockchain: solana_blockchain, currency: sol, subunits: 9)
  end

  let!(:solana_spl_blockchain_currency) do

    contract_address = 'HizyfeSmxUSvER7NJuY4yA9YpG2qwUFEvk6Eby7CzTMP'
    bc = create(:blockchain_currency, blockchain: solana_blockchain, currency: sol_spl,
                   withdraw_fee: 0.025, contract_address: contract_address, subunits: 9, parent: solana_blockchain_currency)
    solana_hot_wallet.currencies = [sol]
    solana_hot_wallet.save
    bc
  end

  let(:solana_spl_payment_address) do
    create(:payment_address, blockchain: solana_blockchain, address: solana_contract_payment_address, parent: solana_payment_address, blockchain_currency: solana_spl_blockchain_currency)
  end
end