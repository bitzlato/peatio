# frozen_string_literal: true

class RenameBlockchainClientToGatewayClass < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :gateway_klass, :string
    Blockchain.where(client: [:dummy]).update_all(gateway_klass: 'BitzlatoGateway')
    Blockchain.where(client: [:bitcoin]).update_all(gateway_klass: 'BitcoinGateway')
    Blockchain.where(client: [:geth, :parity, 'geth-bsc']).update_all(gateway_klass: 'EthereumGateway')
    change_column_null :blockchains, :gateway_klass, false
    remove_column :blockchains, :client
  end
end
