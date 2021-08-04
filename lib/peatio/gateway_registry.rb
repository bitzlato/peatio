require "peatio/adapter_registry"

module Peatio
  module Gateway

    VERSION = "1.0.0".freeze

    class << self
      def registry
        @registry ||= Registry.new
      end
    end
    class Registry < Peatio::AdapterRegistry
    end
  end
end

