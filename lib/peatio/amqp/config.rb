# encoding: UTF-8
# frozen_string_literal: true

module AMQP
  class Config
    class <<self
      def data
        @data ||= Hashie::Mash.new(
          YAML.safe_load(
            ERB.new(File.read(Rails.root.join('config', 'amqp.yml'))).result
          )
        )
      end

      def connect
        data[:connect]
      end

      def binding_exchange_id(id)
        data[:binding][id][:exchange]
      end

      def binding_exchange(id)
        eid = binding_exchange_id(id)
        eid && exchange(eid)
      end

      def binding_queue(id, market = nil)
        queue data[:binding][id][:queue], market
      end

      def binding_worker(id, args = [])
        ::Workers::AMQP.const_get(id.to_s.camelize).new(*args)
      end

      def routing_key(id, market = nil)
        binding_queue(id, market).first
      end

      def topics(id)
        data[:binding][id][:topics].split(',')
      end

      def channel(id)
        (data[:channel] && data[:channel][id]) || {}
      end

      def queue(id, market = nil)
        queue_settings = data.fetch(:queue).fetch(id)
        name = [queue_settings.fetch(:name), market].compact.join('.')
        settings = { durable: queue_settings.dig(:durable) }
        [name, settings]
      end

      def exchange(id)
        type = data[:exchange][id][:type]
        name = data[:exchange][id][:name]
        [type, name]
      end

    end
  end
end
