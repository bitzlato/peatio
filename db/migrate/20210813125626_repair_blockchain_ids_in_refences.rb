# frozen_string_literal: true

class RepairBlockchainIdsInRefences < ActiveRecord::Migration[5.2]
  def change
    # Blockchains:
    #
    # 4 - eth-rinkeby
    # 5 - dummy
    # 6 - bitzlato
    # 7 - eth-mainnet
    # 8 - bsc-mainnet
    #

    Currency.where(blockchain_id: 4).update_all blockchain_id: 7
    Wallet.where(id: 10).update_all blockchain_id: 5
    [Wallet, Withdraw, Deposit, PaymentAddress, WhitelistedSmartContract].each do |model|
      model.where(blockchain_id: 4).update_all blockchain_id: 7
    end

    #
    # Currency
    # Withdraw
    # Deposit
    # PaymentAddress
    #
    # Wallet
    # WhitelistedSmartContract
  end
end
