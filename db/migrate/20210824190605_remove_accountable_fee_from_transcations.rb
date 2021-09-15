# frozen_string_literal: true

class RemoveAccountableFeeFromTranscations < ActiveRecord::Migration[5.2]
  def change
    remove_column :transactions, :accountable_fee
  end
end
