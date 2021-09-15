# frozen_string_literal: true

class RemovePendingTransactions < ActiveRecord::Migration[5.2]
  def change
    Transaction.where(status: :pending).each do |t|
      Rails.logger.debug "Delete pending transction #{t.txid} for blockchain #{t.blockchain.key}"
    end
  end
end
