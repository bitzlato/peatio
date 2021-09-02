module Tron
  class Client
    Error = Class.new(StandardError)

    class ConnectionError < Error; end

    class ResponseError < Error
      def initialize(code, msg)
        super "#{msg} (#{code})"
      end
    end

    extend Memoist

    def initialize(endpoint, idle_timeout: 5)
      @json_rpc_endpoint = URI.parse(endpoint)
      @json_rpc_call_id = 0
      @path = @json_rpc_endpoint.path.empty? ? "/" : @json_rpc_endpoint.path
      @idle_timeout = idle_timeout
    end

    def json_rpc(path, params = {})
      response = connection.post \
        "wallet/#{path}",
        params.merge(visible: true).to_json,
        { 'Accept' => 'application/json',
          'Content-Type' => 'application/json' }
      response.assert_success!
      response = JSON.parse(response.body)
      response
    rescue Faraday::Error => e
      raise ConnectionError, e
    rescue StandardError => e
      raise Error, e
    end

    def get_json_rpc(path, params = nil)
      response = connection.get \
        "wallet/#{path}",
        params,
        { 'Accept' => 'application/json',
          'Content-Type' => 'application/json' }
      response.assert_success!
      response = JSON.parse(response.body)
      response['error'].tap { |error| raise Error, error.inspect if error }
      response
    rescue Faraday::Error => e
      raise ConnectionError, e
    rescue StandardError => e
      raise Error, e
    end

    private

    def rpc_call_id
      @json_rpc_call_id += 1
    end

    def connection
      @connection ||= Faraday.new(@json_rpc_endpoint) do |f|
        f.adapter :net_http_persistent, pool_size: 5, idle_timeout: @idle_timeout
      end.tap do |connection|
        unless @json_rpc_endpoint.user.blank?
          connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
        end
      end
    end
  end
end
