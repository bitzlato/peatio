class MigrateFromGatewayKlassToClientInBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :client, :string

    Blockchain.find_each do |b|
      b.update client: b.read_attribute(:gateway_klass).remove(Blockchain::GATEWAY_PREFIX).downcase
    end

    change_column_null :blockchains, :client, false
    remove_column :blockchains, :gateway_klass
  end
end
