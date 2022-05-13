# frozen_string_literal: true

class SolanaGateway
  class Api
    attr_reader :client, :blockchain

    IDLE_TIMEOUT = 1
    GET_BLOCKS_DEFAULT_LIMIT = 4

    def initialize blockchain
      @blockchain = blockchain
      @client = build_client
    end

    def client_version
      client.json_rpc('getVersion')['solana-core']
    end

    def latest_block_number
      client.json_rpc('getSlot')
    end

    def get_blocks_with_limit block_start, blocks_limit=GET_BLOCKS_DEFAULT_LIMIT
      client.json_rpc('getBlocksWithLimit', [block_start, blocks_limit])
    end

    def get_block slot_id
      client.json_rpc('getBlock', [slot_id])
    end

    def get_transaction tx_id, encoding="json"
      client.json_rpc('getTransaction', [tx_id, encoding])
    end

    def get_balance address
      client.json_rpc('getBalance', [address])['value']
    end

    def send_transaction tx_string
      client.json_rpc('sendTransaction', [tx_string, {encoding: 'base64'}])
    end

    def get_recent_blockhash
      client.json_rpc('getRecentBlockhash')['value']['blockhash']
    end

    def get_token_accounts_by_owner owner_pubkey, mint
      client.json_rpc('getTokenAccountsByOwner', [owner_pubkey, {mint: mint}, {encoding: 'jsonParsed'}])
    end

    def get_account_info pubkey
      client.json_rpc('getAccountInfo', [pubkey, {encoding: 'jsonParsed'}])
    end

    def get_token_account_balance token_account_pubkey
      client.json_rpc('getTokenAccountBalance', [token_account_pubkey])
    end

    private

    def build_client
      client_options = (blockchain.client_options || {}).symbolize_keys
                                                        .slice(:idle_timeout, :read_timeout, :open_timeout)
                                                        .reverse_merge(idle_timeout: IDLE_TIMEOUT)

      Solana::Client.new(blockchain.server, **client_options)
    end
  end
end