require 'peatio/bitzlato/wallet'

class BitzlatoGateway < AbstractGateway
  def poll_deposits!
    client.poll_deposits.each do |intention|
      unless intention[:currency] == currency.id
        Rails.logger.debug("Intention has wrong currency #{intention[:currency]}<>#{currency.id}")
        next
      end
      deposit = Deposit.find_by(currency_id: intention[:currency], invoice_id: intention[:id])
      if deposit.nil?
        Rails.logger.warn("No such deposit intention ##{intention[:id]} for #{currency.id} in blockchain #{blockchain.name}")
        next
      end
      deposit.with_lock do
        next if deposit.accepted?
        unless deposit.amount==intention[:amount]
          Rails.logger.warn("Deposit and intention amounts are not equeal #{deposit.amount}<>#{intention[:amount]} with intention ##{intention[:id]} for #{currency.id} in blockchain #{blockchain.name}")
          next
        end
        unless deposit.invoiced? || deposit.submitted?
          Rails.logger.debug("Deposit #{deposit.id} has skippable status (#{deposit.aasm_state})")
          next
        end
        deposit.accept!

        save_beneficiary currency, deposit, intention[:address]
      end
    end
  end

  def poll_withdraws!
    client.poll_withdraws.each do |withdraw_info|
      next unless withdraw_info.is_done
      next if withdraw_info.withdraw_id.nil?
      withdraw = Withdraw.find_by(id: withdraw_info.withdraw_id)
      if withdraw.nil?
        Rails.logger.warn("No such withdraw withdraw_info ##{withdraw_info.withdraw_id} in blockchain #{blockchain.name}")
        next
      end
      if withdraw.amount!=withdraw_info.amount
        Rails.logger.warn("Withdraw and intention amounts are not equeal #{withdraw.amount}<>#{withdraw_info.amount} with withdraw_info ##{withdraw_info.withdraw_id} in blockchain #{blockchain.name}")
        next
      end
      unless withdraw.confirming?
        Rails.logger.debug("Withdraw #{withdraw.id} has skippable status (#{withdraw.aasm_state})")
        next
      end

      Rails.logger.info("Withdraw #{withdraw.id} successed")
      withdraw.success!
    end
  end

  def create_invoice!(deposit)
    deposit.with_lock do
      raise "Depost has wrong state #{deposit.aasm_state}. Must be submitted" unless deposit.submitted?
      invoice = client.create_invoice!(
        amount: deposit.amount,
        comment: I18n.t('deposit_comment', account_id: deposit.member.uid, deposit_id: deposit.id, email: deposit.member.email)
      )
      deposit.update!(
        data: invoice.slice(:links, :expires_at),
        invoice_id: invoice[:id]
      )
      deposit.invoice!
    end
  end

  private

  # Save beneficiary for future withdraws
  def save_beneficiary(currency, deposit, address)
    unless address.present?
      Rails.logger.warn("Deposit #{deposit.id} has no address to save beneficiaries")
      return
    end
    Rails.logger.info("Save #{address} as beneficiary for #{deposit.account.id}")

    beneficiary_name = [ENV.fetch('BENEFICIARY_PREFIX', 'bitzlato'), address].compact.join(':')

    blockchain.currencies.each do |currency|
      deposit.account.member.beneficiaries
        .create_with(data: { address: address }, state: :active)
        .find_or_create_by!(
          name: beneficiary_name,
          currency: currency
      )
    end
  end

  def build_client
    Bitzlato::Wallet.new
  end
end
