# encoding: UTF-8
# frozen_string_literal: true

# Deprecated
# TODO: Delete this class and update type column
module Withdraws
  class Coin < Withdraw

    before_validation if: :blockchain do
      if blockchain.supports_cash_addr_format? && rid? && CashAddr::Converter.is_valid?(rid)
        self.rid = CashAddr::Converter.to_cash_address(rid)
      end
      unless blockchain.case_sensitive?
        self.rid  = rid.try(:downcase)
        self.txid = txid.try(:downcase)
      end
    end

    validate if: :blockchain do
      if blockchain.supports_cash_addr_format? && rid?
        errors.add(:rid, :invalid) unless CashAddr::Converter.is_valid?(rid)
      end
    end

    def as_json_for_event_api
      super.merge blockchain_confirmations: confirmations
    end
  end
end
