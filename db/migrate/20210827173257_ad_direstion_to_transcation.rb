class AdDirestionToTranscation < ActiveRecord::Migration[5.2]
  def change
    add_column :transactions, :direction, :integer
    Transaction.all.each do |t|
      t.update_column :direction, t.send(:define_direction)
    end
  end
end
