class ChangeDepositIntentionTypeToString < ActiveRecord::Migration[5.2]
  def change
    change_column :deposits, :intention_id, :string
  end
end
