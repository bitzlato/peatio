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
          **payload[:data].slice(:side, :ord_type, :price, :volume, :uuid)
        )
      end
    end
  end
end
