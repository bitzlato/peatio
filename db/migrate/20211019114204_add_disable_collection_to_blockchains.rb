# frozen_string_literal: true

class AddDisableCollectionToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :disable_collection, :boolean, default: false, null: false
  end
end
