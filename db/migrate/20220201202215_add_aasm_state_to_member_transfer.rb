# frozen_string_literal: true

class AddAasmStateToMemberTransfer < ActiveRecord::Migration[5.2]
  def change
    add_column :member_transfers, :aasm_state, :string
  end
end
