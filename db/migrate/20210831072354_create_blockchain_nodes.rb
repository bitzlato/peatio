class CreateBlockchainNodes < ActiveRecord::Migration[5.2]
  def change
    create_table :blockchain_nodes do |t|
      t.references :blockchain, foreign_key: true
      t.string :client
      t.string :server_encrypted

      t.timestamps
    end
  end
end
