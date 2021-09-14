# frozen_string_literal: true

module API
  module V2
    module Management
      module Exceptions
        class Base < StandardError
          def initialize(message:, **options)
            @options = options
            super(message)
          end

          def debug_message
            @options[:debug_message]
          end

          def headers
            @options.fetch(:headers, {})
          end

          def status
            @options.fetch(:status)
          end

          # Change "#<Exception: message>" to "#<Exception: message (debug_message)>".
          def inspect
            debug_message.present? ? super.gsub(/>\z/, " (#{debug_message})>") : super
          end
        end
      end
    end
  end
end
