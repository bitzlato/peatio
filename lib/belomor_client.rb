require 'jwt'
require 'json'
require 'faraday'
require 'faraday_middleware'
require 'openssl'
require 'jwt-multisig'
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

  def initialize(api_url: ENV.fetch('BELOMOR_API_URL'), network_type:)
    @api_url = api_url
    @network_type = network_type
    @adapter = Faraday.default_adapter
    @logger = Faraday::Response::Logger.new(Rails.logger) if ENV.key? 'FARADAY_LOGGER'
  end

  def deposit_address(data)
    data = data.merge(application_key: 'peatio')
    parse_response connection.public_send(:post,'api/management/deposit_addresses', JSON.dump(make_jwt(claims.merge data: data)))
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#create_deposit_address got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def create_address
    data = { network_type: @network_type }
    parse_response connection.public_send(:post,'api/management/addresses', JSON.dump(make_jwt(claims.merge data: data)))
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#create_address got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def latest_block_number
    data = { network_type: @network_type }
    parse_response connection.public_send(:post,'api/management/blockchains/latest_block_number', JSON.dump(make_jwt(claims.merge data: data)))
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#latest_block_number got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  def client_version
    parse_response connection.public_send(:post,'api/management/blockchains/client_version', JSON.dump(make_jwt(claims)))
  rescue WrongResponse => err
    Rails.logger.error "BelomorClient#client_version got error #{err} -> #{err.body} #{err.body.class}"
    :bad_request
  end

  private

  EXPIRE = 30

  def claims
    {
      iat: Time.now.to_i,
      exp: (Time.now + EXPIRE).to_i,
      jti: SecureRandom.hex(10),
      sub: 'session',
      iss: 'peatio',
      aud: %w[belomor]
    }
  end

  def make_jwt(payload)
    private_keychain = {
      peatio: private_key
    }
    algorithms = {
      peatio: ALGORITM
    }
    JWT::Multisig.generate_jwt(payload, private_keychain, algorithms)
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
      c.use Faraday::Response::Logger unless @logger.nil?
      c.headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
      c.request :curl, @logger, :warn if ENV.true?( 'CURL_LOGGER' )
      c.request :json
      c.response :json
      c.adapter @adapter
    end
  end
end
