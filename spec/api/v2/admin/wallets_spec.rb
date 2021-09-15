# frozen_string_literal: true

describe API::V2::Admin::Wallets, type: :request do
  pending

  # let(:blockchain) { find_or_create :blockchain, 'eth-rinkeby', key: 'eth-rinkeby' }
  # let(:blockchain_id) { blockchain.id }
  # let(:admin) { create(:member, :admin, :level_3, email: 'example@gmail.com', uid: 'ID73BF61C8H0') }
  # let(:token) { jwt_for(admin) }
  # let(:level_3_member) { create(:member, :level_3) }
  # let(:level_3_member_token) { jwt_for(level_3_member) }
  # let(:wallet) { Wallet.find_by(blockchain_id: blockchain_id) }

  # describe 'get /api/v2/admin/wallets/:id' do

  # it 'returns information about specified wallet' do
  # api_get "/api/v2/admin/wallets/#{wallet.id}", token: token
  # expect(response).to be_successful

  # result = JSON.parse(response.body)
  # expect(result.fetch('id')).to eq wallet.id
  # expect(result.fetch('currencies')).to eq wallet.currency_ids
  # expect(result.fetch('address')).to eq wallet.address
  # end

  # it 'returns error in case of invalid id' do
  # api_get '/api/v2/admin/wallets/0', token: token

  # expect(response.code).to eq '404'
  # expect(response).to include_api_error('record.not_found')
  # end

  # it 'return error in case of not permitted ability' do
  # api_get "/api/v2/admin/wallets/#{wallet.id}", token: level_3_member_token
  # expect(response.code).to eq '403'
  # expect(response).to include_api_error('admin.ability.not_permitted')
  # end

  # it 'returns information about specified wallet' do
  # api_get "/api/v2/admin/wallets/#{wallet.id}", token: token
  # expect(response).to be_successful
  # result = JSON.parse(response.body)

  # expect(result).not_to include('settings')
  # end

  # it 'returns NA balance if node not accessible' do
  # wallet.update(balance: wallet.current_balance)
  # api_get "/api/v2/admin/wallets/#{wallet.id}", token: token
  # expect(response).to be_successful
  # expect(response_body['balance']).to eq(wallet.current_balance)
  # end

  # it 'returns wallet balance if node accessible' do
  # wallet.update(balance: { 'eth' => '1'})

  # api_get "/api/v2/admin/wallets/#{wallet.id}", token: token
  # expect(response).to be_successful
  # expect(response_body['balance']).to eq({ 'eth' => '1' })
  # end
  # end

  # describe 'GET /api/v2/admin/wallets' do
  # it 'lists of wallets' do
  # api_get '/api/v2/admin/wallets', token: token
  # expect(response).to be_successful

  # result = JSON.parse(response.body)
  # expect(result.size).to eq Wallet.count
  # end

  # it 'returns paginated wallets' do
  # api_get '/api/v2/admin/wallets', params: { limit: 6, page: 1 }, token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful

  # expect(response.headers.fetch('Total')).to eq Wallet.count.to_s
  # expect(result.size).to eq 6
  # expect(result.first['name']).to eq 'Bitcoin Deposit Wallet'

  # api_get '/api/v2/admin/wallets', params: { limit: 6, page: 2 }, token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful

  # expect(response.headers.fetch('Total')).to eq Wallet.count.to_s
  # expect(result.size).to eq 2
  # expect(result.first['name']).to eq 'Ethereum Hot Wallet'
  # end

  # it 'return error in case of not permitted ability' do
  # api_get "/api/v2/admin/wallets", token: level_3_member_token
  # expect(response.code).to eq '403'
  # expect(response).to include_api_error('admin.ability.not_permitted')
  # end

  # context 'filtering' do
  # it 'filters by blockchain key' do
  # api_get "/api/v2/admin/wallets", token: token, params: { blockchain_key: "eth-rinkeby" }

  # result = JSON.parse(response.body)

  # expect(result.length).not_to eq 0
  # expect(result.map { |r| r["blockchain_key"]}).to all eq "eth-rinkeby"
  # end

  # it 'filters by kind'do
  # api_get "/api/v2/admin/wallets", token: token, params: { kind: "deposit" }

  # result = JSON.parse(response.body)

  # expect(result.length).not_to eq 0
  # expect(result.map { |r| r["kind"]}).to all eq "deposit"
  # end

  # context do
  # let(:hot_wallet) { blockchain.wallets.with_currency(:eth).take }

  # before do
  # hot_wallet.currencies << Currency.find(:trst)
  # end

  # it 'filters by currency' do
  # api_get '/api/v2/admin/wallets', token: token, params: { currencies: 'eth' }

  # expect(response_body.length).not_to eq 0
  # expect(response_body.pluck('currencies').map { |a| a.include?('eth') }.all?).to eq(true)
  # count = Wallet.with_currency(:eth).count
  # expect(response_body.find { |c| c['id'] == hot_wallet.id }['currencies'].sort).to eq(%w[eth trst])
  # expect(response_body.count).to eq(count)
  # end

  # it 'filters by currency' do
  # api_get '/api/v2/admin/wallets', token: token, params: { currencies: %w[eth trst] }

  # expect(response_body.length).not_to eq 0
  # count = Wallet.joins(:currencies).where(currencies: { id: %i[eth trst] }).distinct.count
  # expect(response_body.find { |c| c['id'] == hot_wallet.id }['currencies'].sort).to eq(%w[eth trst])
  # expect(response_body.count).to eq(count)
  # end
  # end
  # end
  # end

  # describe 'GET /api/v2/admin/wallets/kinds' do
  # it 'list kinds' do
  # api_get '/api/v2/admin/wallets/kinds', token: token
  # expect(response).to be_successful
  # end
  # end

  # describe 'GET /api/v2/admin/wallets/gateways' do
  # it 'list gateways' do
  # api_get '/api/v2/admin/wallets/gateways', token: token
  # expect(response).to be_successful
  # end
  # end

  # describe 'post /api/v2/admin/wallets/new' do
  # let(:name) { 'test' }
  # it 'create wallet' do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: name,
  # kind: 'deposit',
  # currencies: 'eth',
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'geth',
  # plain_settings: {external_wallet_id: 1},
  # settings: { uri: 'http://127.0.0.1:18332'}
  # },
  # token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['name']).to eq name
  # end

  # it 'create wallet' do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: 'test',
  # kind: 'deposit',
  # currencies: ['eth','trst'],
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'geth',
  # plain_settings: {external_wallet_id: 1},
  # settings: { uri: 'http://127.0.0.1:18332'}
  # },
  # token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['currencies']).to eq(['eth', 'trst'])
  # expect(result['name']).to eq 'test'
  # end

  # it 'checked required params' do
  # api_post '/api/v2/admin/wallets/new', params: { }, token: token

  # expect(response).to have_http_status 422
  # expect(response).to include_api_error('admin.wallet.missing_name')
  # expect(response).to include_api_error('admin.wallet.missing_kind')
  # expect(response).to include_api_error('admin.wallet.currencies_field_is_missing')
  # expect(response).to include_api_error('admin.wallet.missing_blockchain_id')
  # expect(response).to include_api_error('admin.wallet.missing_gateway')
  # end

  # it 'validate status' do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: 'test',
  # kind: 'deposit',
  # currencies: 'eth',
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'geth',
  # plain_settings: {external_wallet_id: 1},
  # settings: { uri: 'http://127.0.0.1:18332'},
  # status: 'disable'
  # },
  # token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_status')
  # end

  # it 'validate gateway' do
  # api_post '/api/v2/admin/wallets/update', params: { name: 'test', kind: 'deposit', currencies: 'eth', address: 'blank', blockchain_id: 'btc-testnet', plain_settings: {external_wallet_id: 1}, settings: { uri: 'http://127.0.0.1:18332'}, gateway: 'test' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.gateway_doesnt_exist')
  # end

  # it 'validate kind' do
  # api_post '/api/v2/admin/wallets/update', params: { name: 'test', kind: 'test', currencies: 'eth', address: 'blank', blockchain_id: 'btc-testnet', plain_settings: {external_wallet_id: 1}, settings: { uri: 'http://127.0.0.1:18332'}, gateway: 'geth' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_kind')
  # end

  # it 'validate currency_id' do
  # api_post '/api/v2/admin/wallets/update', params: { id: 1, name: 'test', kind: 'deposit', address: 'blank', blockchain_id: 'btc-testnet', gateway: 'geth', plain_settings: {external_wallet_id: 1}, settings: { uri: 'http://127.0.0.1:18332'}, currencies: 'test' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.currency_doesnt_exist')
  # end

  # it 'validate uri' do
  # api_post '/api/v2/admin/wallets/new', params: { name: 'test', kind: 'hot', currencies: 'eth', address: 'blank', blockchain_id: 'btc-testnet', plain_settings: {external_wallet_id: 1}, settings: { uri: 'invalid_uri'}, gateway: 'geth' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_uri_setting')
  # end

  # it 'return error in case of not permitted ability' do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: 'Test',
  # kind: 'deposit',
  # currencies: 'eth',
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'geth',
  # plain_settings: {external_wallet_id: 1},
  # settings: { uri: 'http://127.0.0.1:18332'}
  # },
  # token: level_3_member_token

  # expect(response.code).to eq '403'
  # expect(response).to include_api_error('admin.ability.not_permitted')
  # end

  # context 'validate wallet kind is supported by the gateway' do
  # class CustomWallet < Peatio::Wallet::Abstract
  # def initialize(_opts = {}); end
  # def configure(settings = {}); end

  # def support_wallet_kind?(kind)
  # kind == 'hot'
  # end
  # end

  # before(:all) do
  # Peatio::Wallet.registry[:custom] = CustomWallet
  # end

  # it do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: 'Test',
  # kind: 'hot',
  # currencies: [ 'eth', 'trst' ],
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'custom',
  # settings: { uri: 'http://127.0.0.1:18332'}
  # }, token: token

  # expect(response).to be_successful
  # expect(response_body['gateway']).to eq 'custom'
  # end

  # it 'returns error' do
  # api_post '/api/v2/admin/wallets/new',
  # params: {
  # name: 'Test',
  # kind: 'deposit',
  # currencies: ['eth','trst'],
  # address: 'blank',
  # blockchain_id: blockchain.id,
  # gateway: 'custom',
  # settings: { uri: 'http://127.0.0.1:18332'}
  # }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error("Gateway 'custom' can't be used as a 'deposit' wallet")
  # end
  # end
  # end

  # describe 'POST /api/v2/admin/wallets/update' do
  # it 'update wallet' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, gateway: 'geth' }, token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['gateway']).to eq 'geth'
  # end

  # it 'update currency' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, currencies: 'btc' }, token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['currencies']).to eq ['btc']
  # end

  # it 'update wallet with new secret' do
  # api_post '/api/v2/admin/wallets/update',
  # params: { id: wallet.id, currencies: 'btc', settings: { secret: 'new secret' } },
  # token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['currencies']).to eq ['btc']
  # wallet.reload
  # expect(wallet.settings['uri']).to eq nil
  # expect(wallet.settings['secret']).to eq 'new secret'
  # end

  # it 'update wallet with settings' do
  # api_post '/api/v2/admin/wallets/update',
  # params: { id: wallet.id, currencies: 'btc', settings: { secret: 'new secret', access_token: 'new token'} },
  # token: token
  # result = JSON.parse(response.body)

  # expect(response).to be_successful
  # expect(result['currencies']).to eq ['btc']
  # wallet.reload
  # expect(wallet.settings['access_token']).to eq 'new token'
  # expect(wallet.settings['secret']).to eq 'new secret'
  # expect(wallet.settings['uri']).to eq nil
  # end

  # it 'validate blockchain_id' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, blockchain_id: 'test' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.blockchain_id_doesnt_exist')
  # end

  # it 'validate status' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, status: 'disable' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_status')
  # end

  # it 'validate gateway' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, gateway: 'test' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.gateway_doesnt_exist')
  # end

  # it 'validate kind' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, kind: 'test' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_kind')
  # end

  # it 'validate currency_id' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, currencies: 'test ' }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.currency_doesnt_exist')
  # end

  # it 'checked required params' do
  # api_post '/api/v2/admin/wallets/update', params: { }, token: token

  # expect(response).to have_http_status 422
  # expect(response).to include_api_error('admin.wallet.missing_id')
  # end

  # it 'validate uri' do
  # api_post '/api/v2/admin/wallets/update',
  # params: {
  # id: wallet,
  # name: 'test',
  # kind: 'hot',
  # currencies: 'eth',
  # address: 'blank',
  # blockchain_id: 'btc-testnet',
  # settings: { uri: 'invalid_uri'},
  # gateway: 'geth'
  # }, token: token

  # expect(response.code).to eq '422'
  # expect(response).to include_api_error('admin.wallet.invalid_uri_setting')
  # end

  # it 'return error in case of not permitted ability' do
  # api_post '/api/v2/admin/wallets/update', params: { id: wallet.id, status: 'disabled' }, token: level_3_member_token

  # expect(response.code).to eq '403'
  # expect(response).to include_api_error('admin.ability.not_permitted')
  # end
  # end

  # describe 'POST /api/v2/admin/wallets/currencies' do
  # let(:wallet) { Wallet.with_currency(:eth).take }

  # it do
  # api_post '/api/v2/admin/wallets/currencies', params: { id: wallet.id, currencies: 'trst' }, token: token

  # expect(response).to be_successful
  # expect(response_body['currencies'].include?('trst')).to be_truthy
  # end

  # it do
  # api_post '/api/v2/admin/wallets/currencies', params: { id: wallet.id, currencies: 'eth' }, token: token

  # expect(response).to have_http_status 422
  # expect(response).to include_api_error('Currency has already been taken')
  # end
  # end

  # describe 'POST /api/v2/admin/wallets/currencies' do
  # let(:wallet) { Wallet.with_currency(:eth).take }

  # it do
  # api_delete '/api/v2/admin/wallets/currencies', params: { id: wallet.id, currencies: 'eth' }, token: token

  # expect(response).to be_successful
  # expect(response_body['currencies'].include?('eth')).to be_falsey
  # end

  # it do
  # api_delete '/api/v2/admin/wallets/currencies', params: { id: wallet.id, currencies: 'trst' }, token: token

  # expect(response).to have_http_status 404
  # end
  # end
end
