class AddRemoteUsernamesToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :remote_usernames, :json, null: false, default: []
  end
end
