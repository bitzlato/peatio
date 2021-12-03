# frozen_string_literal: true

class ChangeDefaultGroupForMembers < ActiveRecord::Migration[5.2]
  def change
    change_column_default :members, :group, from: 'vip-0', to: 'any'
  end
end
