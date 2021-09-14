class AddUUIDToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :uuid, :binary, limit: 16, after: :id
    add_index :orders, :uuid, unique: true

    %w[created_at updated_at].each do |ts|
      change_column :orders, ts, :datetime, limit: 3
    end
  end
end
