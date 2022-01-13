# frozen_string_literal: true

class SolanaGateway
  class BlockFetcher < Base

    Error = Class.new StandardError

    def perform(slot_id)
      @slot_id = slot_id
      @contract_addresses = blockchain.contract_addresses
      @follow_addresses = blockchain.follow_addresses
      @follow_txids = blockchain.follow_txids.presence

      logger.debug("Fetch block #{slot_id}")

      begin
        block_json = blockchain.gateway.api.get_block(slot_id)
      rescue Peatio::Blockchain::ClientError
        return []
      end

      return [] if block_json.blank? || block_json['transactions'].blank?

      transactions = block_json.fetch('transactions').map do |tx|
        build_transaction(tx) if build_transaction?(tx)
      end.flatten.compact

      logger.info("Fetching block with slot #{slot_id} finished with #{transactions.count} transactions catched")
      transactions.compact.map{|tx| monefy_transaction(tx)}
    rescue Solana::Client::Error => e
      raise Peatio::Blockchain::ClientError, e
    end

    private

    def build_transaction? tx
      account_keys = tx['transaction']['message']['accountKeys']
      txid = tx['transaction']['signatures'].first
      @follow_addresses.nil? || @follow_addresses.intersect?(account_keys.to_set) ||
        (@follow_txids.present? && @follow_txids.include?(txid))
    end

    def build_transaction(transaction)
      txid = transaction['transaction']['signatures'].first
      tx_64 = blockchain.gateway.api.get_transaction(txid, 'base64')['transaction'].first
      detailed_tx = Solana::Tx.from(tx_64)

      defaults = {
        hash: txid,
        status:  transaction['meta']['err'].nil? ? 'success' : 'failed',
        fee_payer_address: detailed_tx.fee_payer,
        block_number: @slot_id
      }

      txs = detailed_tx.instructions.each_with_index.map do |instruction, index|
        instruction_data = parse_instruction(instruction, txid)
        return nil unless (instruction_data.present? and @follow_addresses.intersect?(instruction[:keys].map{|x| x[:pubkey]}.to_set))
        defaults.merge({
                         amount: instruction_data[:amount],
                         from_addresses: [instruction_data[:from]],
                         to_address: instruction_data[:to],
                         instruction_id: index,
                         options: {},
                         contract_address: instruction_data[:contract_address]
                       })
      end.compact

      txs.first[:fee] = transaction['meta']['fee'] if txs.any?

      txs
    end

    def parse_instruction instruction, txid
      keys = instruction[:keys].map{|x| x[:pubkey]}

      parsed_instruction =  case instruction[:program_id]
                            when Solana::Program::Token::PROGRAM_ID
                              parse_token_instruction(instruction, txid, keys)
                            when Solana::Program::System::PROGRAM_ID
                              parse_system_instruction(instruction, txid, keys)
                            when Solana::Program::AssociatedToken::PROGRAM_ID
                              parse_associated_token_instruction(keys)
                            else
                              raise Error, "Unknown program #{instruction[:program_id]} in txid #{txid}"
                            end
    end

    def parse_token_instruction instruction, txid, keys
      params = parse_instruction_params(instruction, Solana::Program::Token::INSTRUCTION_LAYOUTS, txid)
      {
        from: keys[0],
        to: keys[2],
        amount: params[:amount],
        contract_address: keys[1]
      }
    end

    def parse_system_instruction instruction, txid, keys
      params = parse_instruction_params(instruction, Solana::Program::System::INSTRUCTION_LAYOUTS, txid)
      {
        from: keys[0],
        to: keys[1],
        amount: params[:lamports]
      }
    end

    def parse_instruction_params instruction, layouts, txid
      index = instruction[:data].first
      layout = layouts[index]
      raise Error, "Unknown index #{index} for program #{instruction[:program_id]} in tx #{txid}" unless layout.present?
      Solana::Program::Token.decode_data(layout, instruction[:data].dup)
    end

    def parse_associated_token_instruction keys
      {
        from: keys[0],
        to: keys[1],
        amount: Solana::Program::AssociatedToken::LAMPORTS_FOR_TOKEN
      }
    end
  end
end