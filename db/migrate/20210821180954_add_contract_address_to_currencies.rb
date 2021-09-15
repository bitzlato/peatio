# frozen_string_literal: true

class AddContractAddressToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :contract_address, :string
    Currency.find_each do |c|
      c.update contract_address: c.erc20_contract_address
    end
  end
end
