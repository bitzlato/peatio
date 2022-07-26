require 'jwt'
require 'json'
require 'faraday'
require 'faraday_middleware'
require 'openssl'
require 'base64'

class BelomorClient
  class Error < StandardError; end
  class WrongResponse < Error
    attr_reader :body, :status

    def initialize(body: , status: )
      @body = body
      @status = status
    end

    def message
      to_s
    end

    def to_s
      "Wrong response status (#{@status}) with body #{@body}"
    end
  end

  ALGORITM = 'RS256'

  def initialize(api_url: ENV.fetch('BELOMOR_API_URL'), app_key: ENV.fetch('BELOMOR_API_APP_KEY'), blockchain_key:)
    @api_url = api_url
    @app_key = app_key
    @blockchain_key = blockchain_key
    @adapter = Faraday.default_adapter
  end

  def create_address(owner_id:)
    data = { blockchain_key: @blockchain_key, owner_id: owner_id }
    parse_response connection.public_send(:post, 'api/management/addresses', data, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#create_address got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def latest_block_number
    parse_response connection.public_send(:get, "api/management/blockchains/#{@blockchain_key}/latest_block_number", nil, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#latest_block_number got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def client_version
    parse_response connection.public_send(:get, 'api/management/blockchains/client_version', nil, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#client_version got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def address(address)
    data = { blockchain_key: @blockchain_key }
    parse_response connection.public_send(:get, "api/management/addresses/#{address}", data, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#address got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def create_transaction(from_address:, to_address:, amount:, currency_id:)
    data = { blockchain_key: @blockchain_key, from_address: from_address, to_address: to_address, amount: amount, currency_id: currency_id }
    parse_response connection.public_send(:post, 'api/management/transactions', data, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#create_transaction got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def import_address(owner_id:, address:, archived_at:, private_key_hex:, meta: {})
    data = { blockchain_key: @blockchain_key, owner_id: owner_id, address: address, archived_at: archived_at, private_key_hex: private_key_hex, meta: meta }
    parse_response connection.public_send(:post, 'api/management/addresses/import', data, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#import_address got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def create_withdrawal(to_address:, amount:, currency_id:, fee:, owner_id:, remote_id:, meta: {})
    data = { blockchain_key: @blockchain_key, to_address: to_address, amount: amount, currency_id: currency_id, fee: fee, owner_id: owner_id, remote_id: remote_id, meta: meta }
    parse_response connection.public_send(:post, 'api/management/withdraws', data, { 'Authorization' => token })
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#create_withdrawal got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  private

  EXPIRE = 30

  def claims
    {
      iat: Time.now.to_i,
      exp: (Time.now + EXPIRE).to_i,
      jti: SecureRandom.hex(10),
      sub: @app_key,
      iss: 'peatio',
      aud: %w[belomor]
    }
  end

  def token
    jwt = JWT.encode(claims, private_key, ALGORITM)
    "Bearer #{jwt}"
  end

  def parse_response(response)
    raise WrongResponse, status: response.status, body: response.body unless response.success?
    response.body
  end

  def private_key
    return @private_key unless @private_key.nil?
    pkeyio = if ENV.key? 'BELOMOR_MANAGEMENT_PRIVATE_KEY'
      Base64.urlsafe_decode64(ENV.fetch('BELOMOR_MANAGEMENT_PRIVATE_KEY'))
    else
      File.open(ENV.fetch('BELOMOR_MANAGEMENT_PRIVATE_KEY_PATH'))
    end
    @private_key = OpenSSL::PKey.read(pkeyio)
  end

  # Every time build new connection to have fresh jwt token
  def connection
    Faraday.new url: @api_url, ssl: { verify: false } do |c|
      c.headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
      c.request :json
      c.response :json
      c.adapter @adapter
    end
  end
end
