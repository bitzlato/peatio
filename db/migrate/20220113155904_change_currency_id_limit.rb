# frozen_string_literal: true

class ChangeCurrencyIdLimit < ActiveRecord::Migration[5.2]
  def change
    change_column :withdraws, :currency_id, :string, limit: 20
    change_column :accounts, :currency_id, :string, limit: 20
    change_column :beneficiaries, :currency_id, :string, limit: 20
    change_column :blockchain_approvals, :currency_id, :string, limit: 20
    change_column :deposits, :currency_id, :string, limit: 20
    change_column :beneficiaries, :currency_id, :string, limit: 20
    change_column :stats_member_pnl, :pnl_currency_id, :string, limit: 20
    change_column :stats_member_pnl, :currency_id, :string, limit: 20
    change_column :stats_member_pnl_idx, :pnl_currency_id, :string, limit: 20
    change_column :stats_member_pnl_idx, :currency_id, :string, limit: 20
    change_column :markets, :base_unit, :string, limit: 20
    change_column :markets, :quote_unit, :string, limit: 20
    change_column :orders, :bid, :string, limit: 20
    change_column :orders, :ask, :string, limit: 20
  end
end
