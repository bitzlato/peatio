class AddHeightUpdatedAtToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :height_updated_at, :timestamp
  end
end
