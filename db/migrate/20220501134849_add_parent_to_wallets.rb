# frozen_string_literal: true

class AddParentToWallets < ActiveRecord::Migration[5.2]
  def up
    add_reference :wallets, :parent, foreign_key: { to_table: :wallets }
    sol = Currency.find_by(id: 'sol')
    return if sol.blank?

    wallets = sol.wallets
    native_wallet = wallets.find { |w| w.currencies.count == 1 }
    wallets.each do |w|
      w.update_column(:parent_id, native_wallet.id) if w.id != native_wallet.id
    end
  end

  def down
    remove_reference :wallets, :parent, foreign_key: { to_table: :wallets }
  end
end
