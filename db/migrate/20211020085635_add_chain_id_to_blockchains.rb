# frozen_string_literal: true

class AddChainIdToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :chain_id, :integer
  end
end
