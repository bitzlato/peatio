# frozen_string_literal: true

class CreateDepositSpreads < ActiveRecord::Migration[5.2]
  def change
    create_table :deposit_spreads do |t|
      t.references :deposit, foreign_key: true
      t.string :to_address, null: false
      t.string :txid, null: false
      t.string :currency_id, null: false
      t.decimal :amount, null: false
      t.jsonb :meta, null: false, default: []

      t.timestamps
    end

    add_index :deposit_spreads, :txid, unique: true

    Deposit.serialize :spread, Array

    Deposit.where.not(spread: [nil, []]).find_each do |deposit|
      # => [{:to_address=>"0x7075bbbd9bd3e8ce47a0e7ad23170d94c772dfa1",
      # :amount=>"0.017962999969361",
      # :currency_id=>"eth",
      # :status=>"pending",
      # :options=>{"subtract_fee"=>true, "gas_limit"=>21000, "gas_price"=>97000001459}}]
      deposit.spread.each do |spread|
        DepositSpread.create!(
          deposit: deposit,
          to_address: spread.fetch(:to_address),
          amount: spread.fetch(:amount),
          currency_id: spread.fetch(:currency_id),
          txid: spread.fetch(:hash),
          meta: { spread: spread }
        )
      rescue StandardError => e
        Rails.logger.debug { "#{e} for #{spread}" }
      end
    end

    remove_column :deposits, :spread
  end
end
