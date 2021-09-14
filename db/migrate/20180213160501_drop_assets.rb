# frozen_string_literal: true

class DropAssets < ActiveRecord::Migration[4.2]
  def change
    drop_table :assets
  end
end
