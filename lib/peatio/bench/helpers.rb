# frozen_string_literal: true

module Bench
  module Helpers
    def become_billionaire(member)
      @currencies.each do |c|
        c.blockchains.each do |blockchain|
          Factories.create(:deposit, member_id: member.id, blockchain: blockchain, currency_id: c.id)
        end
      end
    end
  end
end
