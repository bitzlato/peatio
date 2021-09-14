# frozen_string_literal: true

class RemoveUrlsFromCurrencies < ActiveRecord::Migration[4.2]
  def change
    remove_column :currencies, :wallet_url_template, :string if column_exists? :currencies, :wallet_url_template
    remove_column :currencies, :transaction_url_template, :string if column_exists? :currencies, :transaction_url_template
  end
end
