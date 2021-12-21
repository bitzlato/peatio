# frozen_string_literal: true

class TronGateway
  module Estimation
    Estimates = Struct.new(:energy_remains, :bandwidth_remains, :bandwidth_price, :energy_price, keyword_init: true)

    def get_account_balance(address)
      client.json_rpc(path: 'wallet/getaccountresource',
                      params: { address: reformat_decode_address(address) })
    end

    def get_estimates(address)
      account_info = get_account_balance(address)

      # energy_price      = (account_info['TotalEnergyLimit'].to_d / account_info['TotalEnergyWeight'].to_d)
      # bandwidth_price   = (account_info['TotalNetLimit'].to_d / account_info['TotalNetWeight'].to_d)
      energy_remains    = (account_info['EnergyLimit'].to_i - account_info['EnergyUsed'].to_i)
      bandwidth_remains = (account_info['NetLimit'].to_i - account_info['NetUsed'].to_i + account_info['freeNetLimit'].to_i - account_info['freeNetUsed'].to_i)

      Estimates.new(
        energy_remains: energy_remains,
        bandwidth_remains: bandwidth_remains
        # energy_price: currency.to_money_from_decimal(1 / energy_price),
        # bandwidth_price: currency.to_money_from_decimal(1 / bandwidth_price)
      )
    end
  end
end
