# frozen_string_literal: true

class DropUselessDepositState < ActiveRecord::Migration[4.2]
  def change
    remove_column :deposits, :state
  end
end
