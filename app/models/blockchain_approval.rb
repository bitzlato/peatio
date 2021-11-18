# frozen_string_literal: true

class BlockchainApproval < ApplicationRecord
  upsert_keys %i[blockchain_id txid]

  belongs_to :currency
  belongs_to :blockchain

  enum status: { pending: 0, success: 1, failed: 2 }

  # Upsert transaction from blockchain
  def self.upsert_transaction!(txn)
    raise 'transaction must be a Peatio::Transaction' unless txn.is_a?(Peatio::Transaction)

    attrs = {
      block_number: txn.block_number,
      status: txn.status,
      owner_address: txn.from_address,
      spender_address: txn.to_address,
      currency_id: txn.currency_id,
      blockchain_id: txn.blockchain_id,
      txid: txn.id,
      options: txn.options
    }
    ba = upsert(attrs)
    Rails.logger.debug { "Transaction (Approval) #{txn.txid} is saved to database with id=#{ba.id}" }
    ba
  rescue ActiveRecord::StatementInvalid, ActiveRecord::RecordInvalid => e
    report_exception e, true, tx: txn, record: e.record.as_json
    raise e
  rescue ActiveRecord::RecordNotUnique => e
    report_exception e, true, tx: txn, record: e.message
    raise e
  end
end
