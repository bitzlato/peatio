# frozen_string_literal: true

class AddCcCodeToCurrencies < ActiveRecord::Migration[5.2]
  def change
    add_column :currencies, :cc_code, :string
  end
end
