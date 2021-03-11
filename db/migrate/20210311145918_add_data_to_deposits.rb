class AddDataToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :data, :json
  end
end
