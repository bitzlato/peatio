# frozen_string_literal: true

class CreateBlockNumbers < ActiveRecord::Migration[5.2]
  def change
    create_table :block_numbers do |t|
      t.references :blockchain, null: false
      t.integer :transactions_processed_count, null: false, default: 0
      t.bigint :number, null: false
      t.string :status, null: false
      t.string :error_message

      t.timestamps
    end

    add_index :block_numbers, %i[blockchain_id number], unique: true
  end
end
