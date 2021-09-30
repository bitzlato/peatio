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
    include Singleton
    attr_reader :notifier
    delegate :ping, :post, to: :notifier

    def initialize
      @notifier = build_notifier
    end

    private

    def build_notifier
      return FakeNotifier if Rails.env.test?
      return FakeNotifier unless ENV.key? 'SLACK_WEBHOOK_URL'
      Slack::Notifier.new ENV.fetch('SLACK_WEBHOOK_URL') do
        defaults channel: ENV.fetch('SLACK_CHANNEL')
      end
    end
  end
end
