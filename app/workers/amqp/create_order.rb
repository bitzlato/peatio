# encoding: UTF-8
# frozen_string_literal: true

module Workers
  module AMQP
    class CreateOrder < Base
      def process(payload)
        payload.symbolize_keys!

        member_id = Member.find_by!(uid: payload[:member_uid]).id

        service = ::OrderServices::CreateOrder.new(member_id, payload[:data])
        order = service.perform
      rescue StandardError => e
        raise e if is_db_connection_error?(e)

        report_exception(e)
      end
    end
  end
end
