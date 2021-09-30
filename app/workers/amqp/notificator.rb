# frozen_string_literal: true

module Workers
  module AMQP
    class Notificator < Base
      def process(_payload)
        Peatio::SlackNotifier.instance.ping 'test'
      end
    end
  end
end
