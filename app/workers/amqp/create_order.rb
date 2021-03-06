# frozen_string_literal: true

module Workers
  module AMQP
    class CreateOrder < Base
      def process(payload)
        payload.symbolize_keys!
        member_uid = payload.fetch(:member_uid)
        order_data = payload.fetch(:data)

        raise 'payload data must be a Hash' unless order_data.is_a? Hash

        order_data.symbolize_keys!

        member = ::Member.find_by!(uid: member_uid)
        market = ::Market.active.find_spot_by_symbol(order_data[:market])

        service = ::OrderServices::CreateOrder.new(member: member)
        service.perform(
          market: market,
          **order_data.slice(:side, :ord_type, :price, :volume, :uuid)
        )
      rescue StandardError, ActiveRecord::RecordNotFound => e
        report_exception(e, true, payload)
      end
    end
  end
end
