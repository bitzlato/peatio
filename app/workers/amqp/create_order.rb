# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class CreateOrder < Base
      def process(payload)
        payload.symbolize_keys!
        member_uid = payload[:member_uid]
        order_data = payload[:data].symbolize_keys

        member = ::Member.find_by!(uid: member_uid)
        market = ::Market.active.find_spot_by_symbol(order_data[:market])

        service = ::OrderServices::CreateOrder.new(member: member)
        order = service.perform(
          market: market,
          **data.slice(:side, :ord_type, :price, :volume, :uuid)
        )
      end
    end
  end
end
