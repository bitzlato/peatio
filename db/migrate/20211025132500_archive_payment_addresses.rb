# frozen_string_literal: true

class ArchivePaymentAddresses < ActiveRecord::Migration[5.2]
  def up
    add_column :payment_addresses, :archived_at, :datetime

    ActiveRecord::Base.connection.exec_update(<<-SQL, 'SQL')
      WITH last_used_payment_addresses AS (
        SELECT ps.member_id, ps.blockchain_id, MAX(t.id) AS t_id, MAX(ps.id) AS ps_id
        FROM payment_addresses ps LEFT JOIN transactions t ON
          LOWER(ps.address) = LOWER(t.from_address) OR LOWER(ps.address) = LOWER(t.to_address)
        GROUP BY ps.member_id, ps.blockchain_id
      )
      UPDATE payment_addresses
      SET archived_at = NOW()
      FROM last_used_payment_addresses
      WHERE payment_addresses.member_id = last_used_payment_addresses.member_id AND
        payment_addresses.blockchain_id = last_used_payment_addresses.blockchain_id AND
        payment_addresses.id <> last_used_payment_addresses.ps_id
    SQL

    add_index :payment_addresses, %i[member_id blockchain_id], unique: true, where: 'archived_at IS NULL'
  end

  def down
    remove_index :payment_addresses, column: %i[member_id blockchain_id]
    remove_column :payment_addresses, :archived_at
  end
end
