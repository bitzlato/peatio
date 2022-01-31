# frozen_string_literal: true

class AddMemberIdToTransfers < ActiveRecord::Migration[5.2]
  def change
    add_reference :transfers, :member, foreign_key: true
    Transfer.find_each do |t|
      members_ids = t.operations.pluck(:member_id).compact

      raise "No member for transfer #{t.id}" if members_ids.blank?
      raise "Too many members for transfer #{t.id}" if members_ids.many?

      member_id = members_ids.first

      t.update! member_id: member_id
    end
    change_column_null :transfers, :member_id, false
  end
end
