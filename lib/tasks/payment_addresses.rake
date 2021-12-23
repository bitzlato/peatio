# frozen_string_literal: true

namespace :payment_addresses do
  desc 'Set common address for eth-like blockchains'
  task combine_addresses: :environment do
    Member.find_each do |member|
      puts "Member ##{member.id}"
      blockchains = Blockchain.where(address_type: 'ethereum')
      common_account ||= Account.joins(:currency).where(member_id: member.id, currencies: { blockchain_id: blockchains.ids }).where.not(balance: 0, locked: 0).take
      common_account ||= Account.joins(:currency).where(member_id: member.id, currencies: { blockchain_id: blockchains.ids }).take
      if common_account.nil?
        puts 'Common account is not found'
        next
      end

      common_address = common_account.payment_address.address
      if BlockchainAddress.where(address: common_address).none?
        puts 'Blockchain address is not found'
        next
      end

      payment_addresses = member.payment_addresses.active.where(blockchain_id: blockchains.ids).where.not(address: common_address)
      payment_addresses.find_each do |payment_address|
        payment_address.update!(archived_at: Time.current)
        member.payment_addresses.create!(blockchain: payment_address.blockchain, address: common_address)
      end
    end
  end
end
