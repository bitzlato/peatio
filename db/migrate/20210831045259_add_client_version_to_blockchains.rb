class AddClientVersionToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :client_version, :string
  end
end
