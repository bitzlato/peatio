# frozen_string_literal: true

class AddWithdrawDisabledAtToMembers < ActiveRecord::Migration[5.2]
  def change
    add_column :members, :withdraw_disabled_at, :timestamp
    add_column :members, :withdraw_disabled_comment, :string
    add_column :members, :withdraw_disabled_by, :integer
    add_foreign_key :members, :members, column: :withdraw_disabled_by

    Member
      .where(uid: %w[IDEABB4E3F7F ID14C2607AE4])
      .update_all withdraw_disabled_at: Time.zone.now, withdraw_disabled_comment: 'Adjusted bots'
  end
end
