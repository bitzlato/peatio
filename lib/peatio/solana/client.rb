# frozen_string_literal: true

module Solana
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

    InvalidSeedError = Class.new ResponseError
    SkippedSlotError = Class.new ResponseError

    extend Memoist

    def initialize(endpoint, idle_timeout: 5, read_timeout: 5, open_timeout: 1)
      @json_rpc_endpoint = URI.parse(endpoint)
      @json_rpc_call_id = 0
      @path = @json_rpc_endpoint.path.empty? ? '/' : @json_rpc_endpoint.path
      @idle_timeout = idle_timeout
      @read_timeout = read_timeout
      @open_timeout = open_timeout
    end

    def raise_error(error)
      if error['message'].include?('Provided seeds do not result in a valid address')
        raise InvalidSeedError.new(error['code'], error['message'], error['data'])
      elsif error['message'].include?('was skipped, or missing in long-term storage')
        raise SkippedSlotError.new(error['code'], error['message'], error['data'])
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
    end

    private

    def rpc_call_id
      @json_rpc_call_id += 1
    end

    def connection
      @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
        # f.request :curl, curl_logger, :info if ENV.true?('ETHEREUM_CURL_LOGGER')
        # f.response :detailed_logger, detailed_logger if ENV.true?('ETHEREUM_DETAILED_LOGGER')
        f.adapter :net_http_persistent, pool_size: 5 do |http|
          http.idle_timeout = @idle_timeout
          http.read_timeout = @read_timeout
          http.open_timeout = @open_timeout
        end
      end.tap do |connection|
        connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password) if @json_rpc_endpoint.user.present?
      end
    end
  end
end
