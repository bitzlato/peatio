# frozen_string_literal: true

class AddExplorerContractAddressToBlockchain < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :explorer_contract_address, :string
  end
end
