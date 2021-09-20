# frozen_string_literal: true

TRANSFER_TYPES = { fiat: 100, crypto: 200 }.freeze

types = YAML.load_file("#{Rails.root}/config/transfer_types.yml").symbolize_keys
DEPOSIT_TRANSFER_TYPES = TRANSFER_TYPES.merge(types[:deposit])
WITHDRAW_TRANSFER_TYPES = TRANSFER_TYPES.merge(types[:withdraw])
