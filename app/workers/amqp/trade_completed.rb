# frozen_string_literal: true

module Workers
  module AMQP
    class TradeCompleted < Base
      FOLLOW_MEMBER_UIDS = ENV.fetch('TRADE_COMPLETED_FOLLOW_MEMBER_UIDS', '').split(',')

      def initialize
        Rails.logger.info "Start TradeCompleted for #{FOLLOW_MEMBER_UIDS.join(', ')}"
        Peatio::SlackNotifier.instance.ping "* Начинаю следить за сделками участников #{FOLLOW_MEMBER_UIDS.join(', ')}"
        super
      end

      def process(payload)
        payload = Hashie::Mash.new(payload)

        member_uid = payload.fetch(:member_uid)

        return if FOLLOW_MEMBER_UIDS.exclude?('all') && !(FOLLOW_MEMBER_UIDS.include? member_uid)

        member = Member.find_by!(uid: member_uid)
        message = generate_message member, payload
        Peatio::SlackNotifier.instance.ping message
      end

      private

      def generate_message(member, payload)
        "Участник #{member.uid} (#{member.email}) совершил сделку (#{payload.side} #{payload.amount} по #{payload.price})' " \
          "на рынке '#{payload.market}' на сумму #{payload.total}" \
          ", ордер ##{payload.order_id}"
      end
    end
  end
end
