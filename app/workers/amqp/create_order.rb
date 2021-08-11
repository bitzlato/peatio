# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class CreateOrder < Base
      def process(payload)
        payload.symbolize_keys!

        @member = Member.find_by!(uid: payload[:member_uid])

        service = ::OrderServices::CreateOrder.new(member_id, payload[:data])
        order = service.perform
      rescue StandardError => e
        ::AMQP::Queue.enqueue_event(
          'private',
          @member.uid,
          'order_error',
          'market.order.create_error',
        )
        report_exception(e)
      end
    end
  end
end
