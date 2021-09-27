module Ethereum
  class Client
    Error = Class.new(StandardError)

    class ConnectionError < Error; end

    class ResponseError < Error
      attr_reader :data

      def initialize(code, message, data = '')
        @data = data
        super [message, "(#{code})", data].compact.join(' ')
      end
    end

    ExecutionError = Class.new ResponseError
    NoEnoughtAmount = Class.new ExecutionError

    ExecutionFailed = Class.new ResponseError
    InsufficientFunds = Class.new ResponseError

    extend Memoist

    def initialize(endpoint, idle_timeout: 5)
      @json_rpc_endpoint = URI.parse(endpoint)
      @json_rpc_call_id = 0
      @path = @json_rpc_endpoint.path.empty? ? '/' : @json_rpc_endpoint.path
      @idle_timeout = idle_timeout
    end

    def raise_error(error)
      # {\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32015,\"message\":\"Transaction execution error.\",\"data\":\"Internal(\\\"Requires higher than upper limit of 300292660\\\")\"},\"id\":11}\n"
      if error['message'].include?('Transaction execution error')
        if error['data'].include?('Requires higher than upper limit')
          raise NoEnoughtAmount.new(error['code'], error['message'], error['data'])
        else
          raise ExecutionError.new(error['code'], error['message'], error['data'])
        end
        # {\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32016,\"message\":\"The execution failed due to an exception.\",\"data\":\"Bad instruction fe\"},\"id\":10}\n"
      elsif error['message'].include?('The execution failed due to an exception')
        # https://app.bugsnag.com/bitzlato/peatio/errors/61376fe4f5fee80007cf80a4?filters%5Bapp.release_stage%5D=production&filters%5Bevent.since%5D=30d&filters%5Berror.status%5D=fixed&filters%5Bsearch%5D%5B%5D=Insufficient&filters%5Bsearch%5D%5B%5D=funds
      elsif error['message'].include?('Insufficient funds')
        raise InsufficientFunds.new(error['code'], error['message'], error['data'])
      else
        raise ResponseError.new(error['code'], error['message'], error['data'])
      end
    end

    def json_rpc(method, params = [])
      response = connection.post \
        @path,
        { jsonrpc: '2.0', id: rpc_call_id, method: method, params: params }.to_json,
        { 'Accept' => 'application/json',
          'Content-Type' => 'application/json' }
      response.assert_success!
      response = JSON.parse(response.body)
      response['error'].tap { |error| raise_error error if error }
      response.fetch('result')

      # We don't want to masquerade errors any more
      # rescue Faraday::Error => e
      # report_exception e, true, method: method
      # raise ConnectionError, e
      # rescue StandardError => e
      # report_exception e, true, method: method
      # raise Error, e
    end

    private

    def rpc_call_id
      @json_rpc_call_id += 1
    end

    def detailed_logger
      @detailed_logger ||= ActiveSupport::Logger.new Rails.root.join('log', 'ethereum_client_detailed.log')
    end

    def curl_logger
      @curl_logger ||= ActiveSupport::Logger.new Rails.root.join('log', 'ethereum_client_curl.log')
    end

    def connection
      @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
        f.request :curl, curl_logger, :info if ENV.true?('ETHEREUM_CURL_LOGGER')
        f.response :detailed_logger, detailed_logger if ENV.true?('ETHEREUM_DETAILED_LOGGER')
        f.adapter :net_http_persistent, pool_size: 5, idle_timeout: @idle_timeout
      end.tap do |connection|
        connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password) if @json_rpc_endpoint.user.present?
      end
    end
  end
end
