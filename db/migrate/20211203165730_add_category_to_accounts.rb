class AddCategoryToAccounts < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :category, :string

    Account.update_all category: 'spot'

    change_column_null :accounts, :category, false

    execute "ALTER TABLE accounts DROP CONSTRAINT accounts_pkey"
    execute "ALTER TABLE accounts ADD COLUMN id BIGSERIAL PRIMARY KEY;"

    add_index :accounts, [:currency_id, :member_id, :category], unique: true
    add_index :accounts, [:category, :currency_id]
  end
end
