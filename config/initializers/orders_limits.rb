# frozen_string_literal: true

# Limit of active (wait and pending) orders for market
#
# key is group name
OPEN_ORDERS_LIMITS = {
  'market-makers' => 50,
  'vip-3' => 5,
  'default' => 2
}.freeze
