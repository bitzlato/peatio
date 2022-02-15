# frozen_string_literal: true

class ChangeRatesLimitsDefaultInMemberGroups < ActiveRecord::Migration[5.2]
  def change
    change_column_default :member_groups, :rates_limits, { 'second' => 10, 'minut' => 100 }
  end
end
