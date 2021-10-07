# frozen_string_literal: true

module Workers
  module AMQP
    # TODO: move to order_processor with bulk_cancel event?
    class CancelMemberOrders < Base
      def process(payload)
        payload.symbolize_keys!
        member_uid = payload[:member_uid]
        member = ::Member.find_by!(uid: member_uid)

        member.orders.active.each(&:trigger_cancellation)
      rescue ActiveRecord::RecordNotFound => e
        report_exception(e, true, payload)
      end
    end
  end
end
