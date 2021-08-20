class AddExplorerContractAddressToBlockchain < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :explorer_contract_address, :string
    Blockchain.find_each do |b|
      b.update explorer_contract_address: 'https://etherscan.io/token/#{contract_address}' if b.key.include? 'eth'
    end
  end
end
