# frozen_string_literal: true

class MigrateFromGatewayKlassToClientInBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :client, :string

    change_column_null :blockchains, :client, false
    remove_column :blockchains, :gateway_klass
  end
end
