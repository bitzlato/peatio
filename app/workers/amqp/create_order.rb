# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class CreateOrder < Base
      def process(payload)
        payload.symbolize_keys!

        @member = ::Member.find_by!(uid: payload[:member_uid])
        market = ::Market.active.find_spot_by_symbol(payload[:data][:market])

        service = ::OrderServices::CreateOrder.new(member_id, payload[:data])
        order = service.perform(
          market: market,
          **payload[:data].slice(:side, :ord_type, :price, :volume)
        )
      rescue ::Account::AccountError => e
        ::AMQP::Queue.enqueue_event(
          'private',
          @member.uid,
          'order_error',
          'market.account.insufficient_balance',
        )
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
