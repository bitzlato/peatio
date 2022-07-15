module Peatio
  module FakeNotifier
    def self.ping(*args)
      Rails.logger.debug("SlackNotifier received ping with args #{args}")
    end

    def self.post(*args)
      Rails.logger.debug("SlackNotifier received post with args #{args}")
    end
  end
  class SlackNotifier
    attr_reader :notifier
    delegate :ping, :post, to: :notifier

    def self.bargainer
      new ENV.fetch('SLACK_BARGAINER_CHANNEL')
    end

    def self.market_bot
      new ENV.fetch('SLACK_MARKET_BOT_CHANNEL')
    end

    def self.notifications
      new ENV.fetch('SLACK_NOTIFICATIONS_CHANNEL')
    end

    def initialize(channel)
      @notifier = build_notifier(channel)
    end

    private

    def build_notifier(channel)
      return FakeNotifier if Rails.env.test?
      return FakeNotifier unless ENV.key? 'SLACK_WEBHOOK_URL'
      Slack::Notifier.new ENV.fetch('SLACK_WEBHOOK_URL') do
        defaults channel: channel
      end
    end
  end
end
