class AddDataToDeposits < ActiveRecord::Migration[5.2]
  def change
    add_column :deposits, :data, :json
    add_column :deposits, :intention_id, :bigint
  end
end
