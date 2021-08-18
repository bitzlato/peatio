# encoding: UTF-8
# frozen_string_literal: true

# Deprecated
# TODO: Delete this class and update type column
module Withdraws
  class Coin < Withdraw

    before_validation if: :blockchain do
      self.rid = blockchain.normalize_address rid
      self.txid = blockchain.normalize_txid txid
    end

    validate if: :blockchain do
      errors.add(:rid, :invalid) unless blockchain.valid_address? rid
    end

    def as_json_for_event_api
      super.merge blockchain_confirmations: confirmations
    end
  end
end
