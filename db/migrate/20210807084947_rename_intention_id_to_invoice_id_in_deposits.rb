# frozen_string_literal: true

class RenameIntentionIdToInvoiceIdInDeposits < ActiveRecord::Migration[5.2]
  def change
    rename_column :deposits, :intention_id, :invoice_id
  end
end
