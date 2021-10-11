# frozen_string_literal: true

class AddHighTransactionPriceAtToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :high_transaction_price_at, :datetime
  end
end
