class AddUniqueIndexToIntentionIdInDeposits < ActiveRecord::Migration[5.2]
  def change
    add_index :deposits, [:currency_id, :intention_id], unique: true, where: 'intention_id is not null'
  end
end
