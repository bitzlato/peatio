class DropLiabilitiesNotNullAddRevenuesMemberId < ActiveRecord::Migration[4.2]
  def change
    change_column_null(:liabilities, :member_id, true)

    add_column(:revenues, :member_id, :integer, null: true, after: :currency_id)
    add_index :revenues, :member_id
  end
end
