# frozen_string_literal: true

class MigrateAllBankModelsToFiat < ActiveRecord::Migration[4.2]
  def change
    execute %( UPDATE deposits SET type = 'Deposits::Fiat' WHERE type = 'Deposits::Bank' )
    execute %( UPDATE withdraws SET type = 'Withdraws::Fiat' WHERE type = 'Withdraws::Bank' )
  end
end
