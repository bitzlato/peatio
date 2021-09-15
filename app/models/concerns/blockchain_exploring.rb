# frozen_string_literal: true

module BlockchainExploring
  def explorer=(hash)
    self[:explorer_address] = hash.fetch('address')
    self[:explorer_transaction] = hash.fetch('transaction')
    self[:explorer_contract_address] = hash.fetch('contract_address', nil)
  end

  def explore_contract_address_url(contract_address)
    explorer_contract_address.gsub('#{contract_address}', contract_address)
  end

  def explore_address_url(address)
    explorer_address.gsub('#{address}', address)
  end

  def explore_transaction_url(txid)
    explorer_transaction.gsub('#{txid}', txid)
  end
end
