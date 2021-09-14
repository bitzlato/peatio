# frozen_string_literal: true

class AddParentIdForeignKeyToCurrencies < ActiveRecord::Migration[5.2]
  def change
    remove_index :currencies, :parent_id
    add_foreign_key :currencies, :currencies, column: :parent_id
  end
end
