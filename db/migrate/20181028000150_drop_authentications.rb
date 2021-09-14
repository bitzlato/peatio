# frozen_string_literal: true

class DropAuthentications < ActiveRecord::Migration[4.2]
  def change
    drop_table :authentications
  end
end
