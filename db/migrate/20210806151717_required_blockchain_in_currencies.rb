# frozen_string_literal: true

class RequiredBlockchainInCurrencies < ActiveRecord::Migration[5.2]
  def change
    Currency.where(blockchain_id: nil).update_all blockchain_id: Blockchain.find_by(key: 'dummy')
    change_column_null :currencies, :blockchain_id, false
  end
end
