# frozen_string_literal: true

class CreateMemberGroups < ActiveRecord::Migration[5.2]
  DEFAULT_RATES_LIMITS = { 'second' => 10, 'minit' => 100 }.freeze

  OPEN_ORDERS_LIMITS = {
    'market-makers' => 50,
    'vip-3' => 5,
    'vip-0' => 4, # bargainer on sandbox
    'default' => 3
  }.freeze

  def open_orders_limit
    member_group.open_orders_limit
    OPEN_ORDERS_LIMITS.fetch(group, OPEN_ORDERS_LIMITS.fetch('default', 3))
  end

  def rates_limits
    { 'second' => 100, 'minut' => 1000 }
  end

  def up
    create_table :member_groups do |t|
      t.string :key, limit: 25, null: false
      t.integer :open_orders_limit, null: false, default: 1
      t.jsonb :rates_limits, null: false, default: DEFAULT_RATES_LIMITS

      t.timestamps
    end

    add_index :member_groups, :key, unique: true

    Member.pluck(:group).each do |key|
      MemberGroup
        .create_with(open_orders_limit: OPEN_ORDERS_LIMITS[key] || 1, rates_limits: DEFAULT_RATES_LIMITS)
        .find_or_create_by!(key: key)
    end
  end

  def down
    drop_table :member_groups
  end
end
