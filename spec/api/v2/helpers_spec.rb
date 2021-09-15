# frozen_string_literal: true

module API
  module V2
    class AuthTest < Grape::API
      get('/auth_test') do
        authenticate!
      end
    end

    class Mount
      mount AuthTest
    end
  end
end

describe API::V2::Helpers, type: :request do
  describe '#authentic?' do
    let!(:member) { create(:member, :level_3) }
    let!(:token) { jwt_for(member) }

    context 'Authenticate using headers' do
      it 'responses successfully' do
        api_get '/api/v2/auth_test', foo: 'bar', hello: 'world', token: token
        expect(response).to be_successful
      end

      it 'does not return authorization header' do
        api_get '/api/v2/auth_test', foo: 'bar', hello: 'world', token: token
        expect(response.headers).not_to include('Authorization')
      end

      it 'sets current user' do
        api_get '/api/v2/auth_test', foo: 'bar', hello: 'world', token: token
        expect(response.body).to eq member.reload.to_json
      end

      it 'fails authorization' do
        get '/api/v2/auth_test'

        expect(response.code).to eq '401'
        expect(response).to include_api_error('jwt.decode_and_verify')
      end
    end
  end

  describe '#authentic_include_username?' do
    let!(:member) { create(:member, username: 'foobar') }
    let!(:token) { jwt_for(member, { username: 'foobar' }) }

    context 'Authenticate using headers' do
      it 'sets current user' do
        api_get '/api/v2/auth_test', token: token
        expect(response.body).to eq member.reload.to_json
      end
    end
  end
end
