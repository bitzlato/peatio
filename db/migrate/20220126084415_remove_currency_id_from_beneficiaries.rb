# frozen_string_literal: true

class RemoveCurrencyIdFromBeneficiaries < ActiveRecord::Migration[5.2]
  def change
    remove_column :beneficiaries, :currency_id, :string, limit: 20
  end
end
