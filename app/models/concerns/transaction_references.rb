# frozen_string_literal: true

module TransactionReferences
  private

  def find_reference
    find_withdraw_as_reference || find_deposit_as_reference || find_wallet_as_reference
  end

  def find_withdraw_as_reference
    blockchain.withdraws.find_by_txid(txid) if txid.present?
  end

  def find_deposit_as_reference
    blockchain.deposits.find_by(txid: txid, txout: txout) if txid.present?
  end

  def find_wallet_as_reference
    return blockchain.wallets.find_by_address(to_address) if to_wallet?
    return blockchain.wallets.find_by_address(from_address) if from_wallet?
  end

  def update_reference
    self.reference ||= find_reference
    # report_exception "Can't detect transaction reference #{id}", true, id: id, txid: txid if self.reference.nil? && success?
  end
end
