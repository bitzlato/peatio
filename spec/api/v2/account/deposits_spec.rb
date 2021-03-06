# frozen_string_literal: true

describe API::V2::Account::Deposits, type: :request do
  let!(:eth) { find_or_create :currency, :eth, id: :eth }
  let!(:trst) { find_or_create :currency, :trst, id: :trst }
  let(:member) { create(:member, :level_3) }
  let(:other_member) { create(:member, :level_3) }
  let(:token) { jwt_for(member) }
  let(:level_0_member) { create(:member, :level_0) }
  let(:level_0_member_token) { jwt_for(level_0_member) }

  before do
    Ability.stubs(:user_permissions).returns({ 'member' => { 'read' => %w[Deposit PaymentAddress] } })
  end

  describe 'GET /api/v2/account/deposits' do
    before do
      create(:deposit_btc, member: member, updated_at: 5.days.ago)
      create(:deposit_usd, member: member, updated_at: 5.days.ago)
      create(:deposit_usd, member: member, txid: 1, amount: 520, updated_at: 5.hours.ago)
      create(:deposit_btc, member: member, txid: 'test', amount: 111, updated_at: 2.hours.ago)
      create(:deposit_usd, member: other_member, txid: 10)
    end

    it 'requires authentication' do
      api_get '/api/v2/account/deposits'
      expect(response.code).to eq '401'
    end

    it 'returns with auth token deposits' do
      api_get '/api/v2/account/deposits', token: token
      expect(response).to be_successful
    end

    it 'returns all deposits num' do
      api_get '/api/v2/account/deposits', token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 4

      expect(response.headers.fetch('Total')).to eq '4'
    end

    it 'returns limited deposits' do
      api_get '/api/v2/account/deposits', params: { limit: 2, page: 1 }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(response.headers.fetch('Total')).to eq '4'

      api_get '/api/v2/account/deposits', params: { limit: 1, page: 2 }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 1
      expect(response.headers.fetch('Total')).to eq '4'
    end

    it 'filters deposits by state' do
      api_get '/api/v2/account/deposits', params: { state: 'canceled' }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 0

      d = create(:deposit_btc, member: member, aasm_state: :canceled)
      api_get '/api/v2/account/deposits', params: { state: 'canceled' }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 1
      expect(result.first['txid']).to eq d.txid
    end

    it 'filters deposits by multiple states' do
      create(:deposit_btc, member: member, aasm_state: :rejected)
      api_get '/api/v2/account/deposits', params: { state: %w[canceled rejected] }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 1

      create(:deposit_btc, member: member, aasm_state: :canceled)
      api_get '/api/v2/account/deposits', params: { state: %w[canceled rejected] }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 2
    end

    it 'returns deposits for the last two days' do
      api_get '/api/v2/account/deposits', params: { limit: 5, page: 1, time_from: 2.days.ago.to_i }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(response.headers.fetch('Total')).to eq '2'
    end

    it 'returns deposits before 2 days ago' do
      api_get '/api/v2/account/deposits', params: { time_to: 2.days.ago.to_i }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(response.headers.fetch('Total')).to eq '2'
    end

    it 'returns deposits for currency usd' do
      api_get '/api/v2/account/deposits', params: { currency: 'usd' }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 2
      expect(result).to be_all { |d| d['currency'] == 'usd' }
    end

    it 'returns deposits with txid filter' do
      api_get '/api/v2/account/deposits', params: { txid: Deposit.first.txid }, token: token
      result = JSON.parse(response.body)

      expect(result.size).to eq 1
      expect(result).to be_all { |d| d['txid'] == Deposit.first.txid }
    end

    it 'returns deposits for currency btc' do
      api_get '/api/v2/account/deposits', params: { currency: 'btc' }, token: token
      result = JSON.parse(response.body)

      expect(response.headers.fetch('Total')).to eq '2'
      expect(result).to be_all { |d| d['currency'] == 'btc' }
    end

    it 'return 404 if txid not exist' do
      api_get '/api/v2/account/deposits/5', token: token
      expect(response.code).to eq '404'
      expect(response).to include_api_error('record.not_found')
    end

    it 'returns 404 if txid not belongs_to you ' do
      api_get '/api/v2/account/deposits/10', token: token
      expect(response.code).to eq '404'
      expect(response).to include_api_error('record.not_found')
    end

    it 'returns deposit txid if exist' do
      api_get '/api/v2/account/deposits/1', token: token
      result = JSON.parse(response.body)

      expect(response.code).to eq '200'
      expect(result['amount']).to eq '520.0'
    end

    it 'returns deposit no time limit ' do
      api_get '/api/v2/account/deposits/test', token: token
      result = JSON.parse(response.body)

      expect(response.code).to eq '200'
      expect(result['amount']).to eq '111.0'
    end

    it 'denies access to unverified member' do
      api_get '/api/v2/account/deposits', token: level_0_member_token
      expect(response.code).to eq '403'
      expect(response).to include_api_error('account.deposit.not_permitted')
    end

    context 'fail' do
      it 'validates time_from param' do
        api_get '/api/v2/account/deposits', params: { time_from: 'btc' }, token: token

        expect(response.code).to eq '422'
        expect(response).to include_api_error('account.deposit.non_integer_time_from')
      end

      it 'validates time_to param' do
        api_get '/api/v2/account/deposits', params: { time_to: [] }, token: token

        expect(response.code).to eq '422'
        expect(response).to include_api_error('account.deposit.non_integer_time_to')
      end
    end

    context 'unauthorized' do
      before do
        Ability.stubs(:user_permissions).returns([])
      end

      it 'renders unauthorized error' do
        api_get '/api/v2/account/deposits/test', token: token

        expect(response).to have_http_status :forbidden
        expect(response).to include_api_error('user.ability.not_permitted')
      end
    end
  end

  describe 'GET /api/v2/account/deposit_address/:blockchain_id' do
    context 'failed' do
      it 'validates blockchain' do
        api_get '/api/v2/account/deposit_address/100500', token: token
        expect(response).to have_http_status :unprocessable_entity
        expect(response).to include_api_error('account.blockchain.doesnt_exist')
      end

      context 'unauthorized' do
        let(:blockchain) { find_or_create :blockchain, 'eth-ropsten', key: 'eth-ropsten' }

        before do
          Ability.stubs(:user_permissions).returns([])
        end

        it 'renders unauthorized error' do
          api_get "/api/v2/account/deposit_address/#{blockchain.id}", token: token
          expect(response).to have_http_status :forbidden
          expect(response).to include_api_error('user.ability.not_permitted')
        end
      end
    end

    context 'successful' do
      context 'eth address' do
        let(:currency) { eth }
        let(:blockchain) { find_or_create :blockchain, 'eth-rinkeby', key: 'eth-rinkeby' }
        let(:address) { Faker::Blockchain::Ethereum.address }

        before do
          member.payment_address(blockchain).update!(address: address)
        end

        it 'expose data about eth address' do
          api_get "/api/v2/account/deposit_address/#{blockchain.id}", token: token

          expect(response_body).to include_json(
            {
              currencies: UnorderedArray('eth', 'trst', 'ring'),
              address: blockchain.normalize_address(address),
              state: 'active'
            }
          )
        end

        it 'pending user address state' do
          member.payment_address(blockchain).update!(address: nil)
          api_get "/api/v2/account/deposit_address/#{blockchain.id}", token: token

          expect(response_body).to include_json(
            {
              currencies: UnorderedArray('trst', 'eth', 'ring'),
              address: nil,
              state: 'pending'
            }
          )
        end

        context 'currency code with dot' do
          it 'returns information about specified deposit address' do
            currency = create(:currency, :xagm_cx)
            parent = BlockchainCurrency.find_by!(blockchain: blockchain, currency: eth)
            create(:blockchain_currency, blockchain: blockchain, currency: currency, contract_address: 'xa9mcx', parent: parent)
            api_get "/api/v2/account/deposit_address/#{blockchain.id}", token: token
            expect(response).to have_http_status :ok
            expect(response_body).to include_json(
              {
                currencies: UnorderedArray('eth', 'trst', 'ring', 'xagm.cx'),
                address: address.downcase,
                state: 'active'
              }
            )
          end
        end
      end
    end
  end
end
