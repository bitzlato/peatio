class ChangeMemberEmailTypeToCitext < ActiveRecord::Migration[5.2]
  def change
    change_column :members, :email, :citext
  end
end
