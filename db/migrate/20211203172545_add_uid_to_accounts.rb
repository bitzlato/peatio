class AddUidToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :uid, :string

    Account.find_each do |a|
      a.send :assign_uid
      a.save!
    end
    change_column_null :accounts, :uid, false
    add_index :accounts, :uid, unique: true
  end
end
