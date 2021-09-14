# frozen_string_literal: true

describe API::V2::Management::JWTAuthenticationMiddleware, type: :request do
  let(:member) { create(:member, :level_3) }
  let(:config) { management_api_v1_security_configuration }

  before do
    defaults_for_management_api_v1_security_configuration!
    config.merge! \
      scopes: {
        tools: { permitted_signers: %i[alex jeff], mandatory_signers: %i[alex] }
      }
  end

  it 'works in standard conditions' do
    post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({}, :alex)
    expect(response).to be_successful
  end

  it 'allows only POST, PUT, and DELETE' do
    get '/api/v2/management/timestamp'
    expect(response).to have_http_status(:method_not_allowed)

    patch '/api/v2/management/timestamp'
    expect(response).to have_http_status(:method_not_allowed)

    head '/api/v2/management/timestamp'
    expect(response).to have_http_status(:method_not_allowed)
  end

  it 'doesn\'t allow query parameters' do
    post '/api/v2/management/timestamp?foo=baz&baz=qux'
    expect(response).to have_http_status(:bad_request)
    expect(response.body).to match(/query parameters/i)
  end

  it 'requires JSON in the request body' do
    post '/api/v2/management/timestamp', params: { foo: 'baz', baz: 'qux' }
    expect(response).to have_http_status(:bad_request)
    expect(response.body).to match(/only json/i)
  end

  it 'denies access when not enough signatures are supplied' do
    post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({})
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).to match(/not enough signatures/i)
  end

  it 'denies access when token is expired' do
    config[:jwt][:verify_expiration] = true
    post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ exp: 1.minute.ago.to_i }, :alex)
    expect(response).to have_http_status(:unauthorized)
    expect(response.body).to match(/failed to verify jwt/i)
  end

  context 'valid issuer' do
    before { config[:jwt][:verify_iss] = true }

    before { config[:jwt].merge!(iss: 'qux') }

    it 'validates issuer' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ iss: 'qux' }, :alex)
      expect(response).to be_successful
    end
  end

  context 'invalid issuer' do
    before { config[:jwt][:verify_iss] = true }

    before { config[:jwt].merge!(iss: 'qux') }

    it 'validates issuer' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ iss: 'hacker' }, :alex)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/failed to verify jwt/i)
    end
  end

  context 'valid audience' do
    before { config[:jwt][:verify_aud] = true }

    before { config[:jwt].merge!(aud: 'qux') }

    it 'validates audience' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ aud: 'qux' }, :alex)
      expect(response).to be_successful
    end
  end

  context 'invalid audience' do
    before { config[:jwt][:verify_aud] = true }

    before { config[:jwt].merge!(aud: 'qux') }

    it 'validates audience' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ aud: 'hacker' }, :alex)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/failed to verify jwt/i)
    end
  end

  context 'missing JWT ID' do
    before { config[:jwt][:verify_jti] = true }

    it 'requires JTI' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({}, :alex)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/failed to verify jwt/i)
    end
  end

  context 'issued at in future' do
    before { config[:jwt][:verify_iat] = true }

    it 'denies access' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ iat: 200.seconds.from_now.to_i }, :alex)
      expect(response).to have_http_status(:unauthorized)
      expect(response.body).to match(/failed to verify jwt/i)
    end
  end

  context 'issued at before future' do
    before { config[:jwt][:verify_iat] = true }

    it 'allows access' do
      post_json '/api/v2/management/timestamp', multisig_jwt_management_api_v1({ iat: 3.seconds.ago.to_i }, :alex)
      expect(response).to have_http_status(:ok)
    end
  end
end
