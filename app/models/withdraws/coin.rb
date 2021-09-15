# frozen_string_literal: true

# Deprecated
# TODO: Delete this class and update type column
module Withdraws
  class Coin < Withdraw
    before_validation if: :blockchain do
      self.rid = blockchain.normalize_address rid if rid?
      self.txid = blockchain.normalize_txid txid if txid?
    end

    validate if: :blockchain do
      return unless rid?

      errors.add(:rid, :invalid) unless blockchain.valid_address? rid
    end

    def as_json_for_event_api
      super.merge blockchain_confirmations: confirmations
    end
  end
end
