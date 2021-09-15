# frozen_string_literal: true

class ChangeBidToRid < ActiveRecord::Migration[4.2]
  def change
    rename_column :withdraws, :bid, :rid
  end
end
