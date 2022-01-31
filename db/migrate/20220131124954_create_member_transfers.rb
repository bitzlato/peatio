class CreateMemberTransfers < ActiveRecord::Migration[5.2]
  def change
    create_table :member_transfers do |t|
      t.references :member, foreign_key: true, null: false
      t.string :currency_id, null: false
      t.string :service, null: false
      t.decimal :amount, null: false
      t.string :key, null: false
      t.text :description, null: false
      t.jsonb :meta, null: false, default: {}

      t.timestamps
    end

    add_index :member_transfers, :key, unique: true
    add_index :member_transfers, :currency_id
  end
end
