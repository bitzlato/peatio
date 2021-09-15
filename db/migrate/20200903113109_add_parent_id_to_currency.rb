# frozen_string_literal: true

class AddParentIdToCurrency < ActiveRecord::Migration[5.2]
  def change
    add_reference :currencies, :parent, type: :string, index: true, after: :blockchain_key
  end
end
