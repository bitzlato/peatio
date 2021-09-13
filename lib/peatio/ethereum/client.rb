module Ethereum
  class Client
    Error = Class.new(StandardError)

    class ConnectionError < Error; end

    class ResponseError < Error
      attr_reader :data
      def initialize(code, message, data = '')
        @data = data
        super "#{message} (#{code})"
      end
    end

    NoEnoughtAmount = Class.new ResponseError

    extend Memoist

    def initialize(endpoint, idle_timeout: 5)
      @json_rpc_endpoint = URI.parse(endpoint)
      @json_rpc_call_id = 0
      @path = @json_rpc_endpoint.path.empty? ? "/" : @json_rpc_endpoint.path
      @idle_timeout = idle_timeout
    end

    def raise_error(error)
      # "Accept: application/json\nContent-Type: application/json\nUser-Agent: Faraday v1.5.1\n\n{\"jsonrpc\":\"2.0\",\"id\":11,\"method\":\"eth_estimateGas\",\"params\":[{\"gasPrice\":\"0x1b6f2970f1\",\"from\":\"0x97d92440fce7096eb7d3859d790ccaae6adb6bee\",\"to\":\"0xdac17f958d2ee523a2206206994597c13d831ec7\",\"data\":\"0xa9059cbb0000000000000000000000008a988dc81b42be7a3ad343c4d4fa3eac3ead3dc40000000000000000000000000000000000000000000000000000000000000001\"}]}"
      # rcontent-length: 160\ncontent-type: application/json; charset=utf-8\ndate: Fri, 10 Sep 2021 17:42:21 GMT\n\n{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32015,\"message\":\"Transaction execution error.\",\"data\":\"Internal(\\\"Requires higher than upper limit of 300292660\\\")\"},\"id\":11}\n"
      if error['message'].include?('Transaction execution error') && error['data'].include?('Requires higher than upper limit')
        raise NoEnoughtAmount.new(error['code'], error['data'])
      else
        raise ResponseError.new(error['code'], error['message'], error['data'])
      end
    end

    def json_rpc(method, params = [])
      response = connection.post \
          @path,
          {jsonrpc: '2.0', id: rpc_call_id, method: method, params: params}.to_json,
          {'Accept' => 'application/json',
           'Content-Type' => 'application/json'}
      response.assert_success!
      response = JSON.parse(response.body)
      response['error'].tap { |error| raise_error error if error }
      response.fetch('result')

      # We don't want to masquerade errors any more
    #rescue Faraday::Error => e
      #report_exception e, true, method: method
      #raise ConnectionError, e
    #rescue StandardError => e
      #report_exception e, true, method: method
      #raise Error, e
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
        unless @json_rpc_endpoint.user.blank?
          connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
        end
      end
    end
  end
end
