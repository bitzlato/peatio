# frozen_string_literal: true

# Limit of active (wait and pending) orders for market
#
# key is group name
OPEN_ORDERS_LIMITS = {
  'market-makers' => 20,
  'vip-3' => 20,
  'other' => 5
}.freeze
