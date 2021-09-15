# frozen_string_literal: true

class RemoveKeyFromCurrency < ActiveRecord::Migration[4.2]
  def change
    remove_column :currencies, :key
  end
end
