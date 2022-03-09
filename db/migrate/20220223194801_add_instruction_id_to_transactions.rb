class AddInstructionIdToTransactions < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :instruction_id, :integer
  end
end
