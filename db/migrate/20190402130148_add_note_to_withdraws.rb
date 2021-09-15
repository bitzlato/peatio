# frozen_string_literal: true

class AddNoteToWithdraws < ActiveRecord::Migration[5.0]
  def change
    add_column :withdraws, :note, :string, limit: 256, after: :rid
  end
end
