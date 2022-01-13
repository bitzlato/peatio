# frozen_string_literal: true

# NOTE: The order of task matters because Currency belongs_to Blockchain.
Rake::Task['seed:accounts'].invoke
Rake::Task['seed:blockchains'].invoke
Rake::Task['seed:currencies'].invoke
Rake::Task['seed:engines'].invoke
Rake::Task['seed:markets'].invoke
Rake::Task['seed:wallets'].invoke
Rake::Task['seed:trading_fees'].invoke

blockchain = Blockchain.find_by!(key: 'bitzlato')
BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('usd'))
BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('btc'))
blockchain = Blockchain.find_by!(key: 'eth-ropsten')
parent_blockchain_currency = BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('eth'), gas_limit: 21_000)
BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('trst'), contract_address: '0x0000000000000000000000000000000000000000', gas_limit: 90_000, parent_id: parent_blockchain_currency.id)
blockchain = Blockchain.find_by!(key: 'bsc-testnet')
parent_blockchain_currency = BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('bnb-bep20'), gas_limit: 21_000)
BlockchainCurrency.create!(blockchain: blockchain, currency: Currency.find('usdt-bep20'), contract_address: '0x337610d27c682E347C9cD60BD4b3b107C9d34dDd', gas_limit: 100_000, parent_id: parent_blockchain_currency.id)

Member.create!(level: 3, role: 'member', uid: 'U123456789', state: :active)
