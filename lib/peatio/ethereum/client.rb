module Ethereum
  class Client
    Error = Class.new(StandardError)

    class ConnectionError < Error; end

    class ResponseError < Error
      attr_reader :request_data
      def initialize(code, message, request_data = nil)
        @request_data = request_data
        super "#{message} (#{code})"
      end
    end

    extend Memoist

    def initialize(endpoint, idle_timeout: 5)
      @json_rpc_endpoint = URI.parse(endpoint)
      @json_rpc_call_id = 0
      @path = @json_rpc_endpoint.path.empty? ? "/" : @json_rpc_endpoint.path
      @idle_timeout = idle_timeout
    end

    def json_rpc(method, params = [])
      response = connection.post \
          @path,
          {jsonrpc: '2.0', id: rpc_call_id, method: method, params: params}.to_json,
          {'Accept' => 'application/json',
           'Content-Type' => 'application/json'}
      response.assert_success!
      response = JSON.parse(response.body)
      response['error'].tap { |error| raise ResponseError.new(error['code'], error['message'], params) if error }
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

    def connection
      @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
        f.request :curl, Rails.logger, :warn if ENV.true?('ETHEREUM_FARADAY_CURL_LOGGER')
        f.adapter :net_http_persistent, pool_size: 5, idle_timeout: @idle_timeout
      end.tap do |connection|
        unless @json_rpc_endpoint.user.blank?
          connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
        end
      end
    end
  end
end
