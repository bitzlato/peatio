# frozen_string_literal: true

module Workers
  module AMQP
    class TradeCompleted < Base
      FOLLOW_MEMBER_UIDS = ENV.fetch('TRADE_COMPLETED_FOLLOW_MEMBER_UIDS', '').split(',')
      BARGAINER_UID = ENV.fetch('BARGAINER_UID', nil)
      LIZA_ROOT_URL = ENV.fetch('LIZA_ROOT_URL', nil)

      def initialize
        Rails.logger.info "Start TradeCompleted for #{FOLLOW_MEMBER_UIDS.join(', ')}"
        if Rails.env.production?
          Peatio::SlackNotifier.instance.ping "* Начинаю следить за сделками участников #{FOLLOW_MEMBER_UIDS.join(', ')} и проторговщиком #{BARGAINER_UID}"
        end
        super
      end

      def process(payload)
        payload = Hashie::Mash.new(payload)

        member_uid = payload.fetch(:member_uid)

        if FOLLOW_MEMBER_UIDS.include?('all') || FOLLOW_MEMBER_UIDS.include?(member_uid)
          member = Member.find_by!(uid: member_uid)
          message = generate_follow_message member, payload
          Peatio::SlackNotifier.instance.ping message
        end

        binding.pry
        other_member_uid = payload.fetch(:other_member_uid)
        if BARGAINER_UID.present? && member_uid == BARGAINER_UID && other_member_uid != BARGAINER_UID
          member ||= Member.find_by!(uid: member_uid)
          message = generate_bargainer_message member, payload
          Peatio::SlackNotifier.instance.ping message
        end
      end

      private

      def liza_order_url(order_id)
        return order_id if LIZA_ROOT_URL.nil?
        link( LIZA_ROOT_URL + '/orders/' + order_id.to_s, order_id)
      end

      def liza_trade_url(trade_id)
        return trade_id if LIZA_ROOT_URL.nil?
        link(LIZA_ROOT_URL + '/trades/' + trade_id.to_s, trade_id)
      end

      def liza_member_url(member_id)
        return member_id if LIZA_ROOT_URL.nil?
        link(LIZA_ROOT_URL + '/members/' + member_id.to_s, member_id)
      end

      def link(url, text)
        "[#{text}](#{url})"
      end

      def message_prefix
        "(#{Rails.env}) " unless Rails.env.production?
      end

      def generate_bargainer_message(member, payload)
        "#{message_prefix}Проторговщик #{liza_member_url member.uid} (#{member.email}) совершил сделку (#{payload.side} #{payload.amount} по #{payload.price}) с другим участником рынка" \
          " '#{payload.market}' на сумму #{payload.total}" \
          ", ордер ##{liza_order_url payload.order_id}, сделка ##{liza_trade_url payload.id}"
      end

      def generate_follow_message(member, payload)
        "#{message_prefix}Участник #{liza_member_url member.uid} (#{member.email}) совершил сделку (#{payload.side} #{payload.amount} по #{payload.price}) " \
          "на рынке '#{payload.market}' на сумму #{payload.total}" \
          ", ордер ##{liza_trade_url payload.order_id}, сделка ##{liza_trade_url payload.id}"
      end
    end
  end
end
