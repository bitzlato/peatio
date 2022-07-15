# frozen_string_literal: true

class RemoveHighTransactionPriceAtFromBlockchains < ActiveRecord::Migration[6.0]
  def change
    remove_column :blockchains, :high_transaction_price_at, :datetime
  end
end
