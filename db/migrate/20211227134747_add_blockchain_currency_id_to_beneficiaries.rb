# frozen_string_literal: true

class AddBlockchainCurrencyIdToBeneficiaries < ActiveRecord::Migration[5.2]
  def change
    add_column :beneficiaries, :blockchain_currency_id, :bigint
    change_column_null :beneficiaries, :currency_id, true
    Beneficiary.find_each do |beneficiary|
      blockchain_currency = BlockchainCurrency.find_by!(currency_id: beneficiary.currency_id)
      beneficiary.update_column(:blockchain_currency_id, blockchain_currency.id)
    end
    change_column_null :beneficiaries, :blockchain_currency_id, false
  end
end
