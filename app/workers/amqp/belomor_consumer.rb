# frozen_string_literal: true

module Workers
  module AMQP
    class BelomorConsumer < Base
      class IncorrectPayloadError < StandardError; end

      private

      JWT_ALGORITHM = 'RS256'

      def verify_payload!(payload)
        result = JWT.decode(payload['signature'], public_key, true, { algorithm: JWT_ALGORITHM })
        raise IncorrectPayloadError if result[0].except('iat', 'exp') != payload.except('signature')
      end

      def public_key
        @public_key ||= OpenSSL::PKey.read(Base64.urlsafe_decode64(ENV.fetch('BELOMOR_JWT_PUBLIC_KEY')))
      end
    end
  end
end
