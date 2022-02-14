# frozen_string_literal: true

class AddSquashTokenToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_reference :currencies, :merged_token, foreign_key: { to_table: :currencies }, type: :string, length: 20

    Currency.find_each do |c|
      c.update! merged_token_id: c.token_name if c.legacy?
    end
  end
end
