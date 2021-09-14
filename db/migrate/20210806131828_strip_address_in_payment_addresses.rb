# frozen_string_literal: true

class StripAddressInPaymentAddresses < ActiveRecord::Migration[5.2]
  def change
    PaymentAddress.where(address: '').update_all address: nil

    add_index :payment_addresses, %i[blockchain_id address], unique: true, where: 'address is not null'
  end
end
