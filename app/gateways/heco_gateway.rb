class HecoGateway < EthereumGateway
  # eth_blockNumber always returns 0 ;(
  def latest_block_number
    client.json_rpc(:eth_syncing).fetch('currentBlock').to_i(16)
  end
end
