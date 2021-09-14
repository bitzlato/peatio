# frozen_string_literal: true

class RemoveSnFromWithdraw < ActiveRecord::Migration[4.2]
  def change
    remove_column :withdraws, :sn
  end
end
