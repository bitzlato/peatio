# frozen_string_literal: true

class RemoveMinConfirmationsFromBlockchains < ActiveRecord::Migration[6.0]
  def change
    remove_column :blockchains, :min_confirmations, :integer, default: 6, null: false
  end
end
