# frozen_string_literal: true

class RemoveIdSequenceFromCurrencies < ActiveRecord::Migration[5.2]
  def up
    execute 'drop sequence currencies_id_seq cascade' if defined? PG
  end

  def down; end
end
