# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class Base
      def is_db_connection_error?(exception)
        (defined?(Mysql2) && (exception.is_a?(Mysql2::Error::ConnectionError) || exception.cause.is_a?(Mysql2::Error))) ||
          (defined?(PG) && exception.is_a?(PG::Error))
      end
    end
  end
end
