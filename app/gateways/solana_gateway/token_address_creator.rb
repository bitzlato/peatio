class SolanaGateway
  class TokenAddressCreator < Base
    def find_or_create_token_account(owner_address, contract_address, signer)
      token_account_pubkey = get_token_account(owner_address, contract_address)
      return token_account_pubkey if token_account_pubkey.present?
      create_token_account(owner_address, contract_address, signer)
    end

    private

    def get_token_account owner_address, contract_address
      accounts = api.get_token_accounts_by_owner(owner_address, contract_address)
      account = accounts['value'].first
      account['pubkey'] if account.present?
    end

    def create_token_account(owner_address, contract_address, signer)
      i = 255
      txid = nil
      while (txid.nil? and i > 0)
        tx = Solana::Tx.new
        associated_account_pubkey = Solana::Program::AssociatedToken.generate_associated_token_account(contract_address, owner_address, i)
        params = {
          payer_pubkey: signer.address,
          associated_account_pubkey: associated_account_pubkey,
          owner_pubkey: owner_address,
          token_pubkey: contract_address
        }

        instruction = Solana::Program::AssociatedToken.create_associated_token_account_instruction(params)
        tx.recent_blockhash = api.get_recent_blockhash
        tx.add(instruction)

        tx.sign([signer.private_key])
        begin
          txid = api.send_transaction(tx.to_base64)
        rescue Solana::Client::InvalidSeedError
        end
        i-=1
      end
      associated_account_pubkey
    end
  end
end
