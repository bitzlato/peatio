module Tron
  class Client
    Error = Class.new(StandardError)

    class ConnectionError < Error; end

    class ResponseError < Error
      def initialize(code, msg)
        @code = code
        @msg = msg
      end

      def message
        "#{@msg} (#{@code})"
      end
    end

    extend Memoist

    def initialize(endpoint)
      @json_rpc_endpoint = URI.parse(endpoint)
    end

    def json_rpc(path:, params: {})
      response = connection.post do |req|
        req.url path
        req.body = params.to_json
      end
      response.assert_success!
      response = JSON.parse(response.body)
      return response if response.is_a?(Array)
      response['Error'].tap { |error| raise ResponseError.new(200, error) if error }
      response
    rescue => e
      if e.is_a?(Error)
        raise e
      elsif e.is_a?(Faraday::Error)
        raise ConnectionError, e
      else
        raise Error, e
      end
    end

    private

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
