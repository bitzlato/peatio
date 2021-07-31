class RemoveIdSequenceFromCurrencies < ActiveRecord::Migration[5.2]
  def up
    if defined? PG
      execute 'drop sequence currencies_id_seq cascade'
    end
  end

  def down
  end
end
