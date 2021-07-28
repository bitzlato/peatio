class AddSymbolSuffixToBlockchains < ActiveRecord::Migration[5.2]
  def change
    add_column :blockchains, :symbol_suffix, :string
    Blockchain.find_each do |b|
      b.update symbol_suffix: b.key.split('-').first
    end
    change_column_null :blockchains, :symbol_suffix, false
  end
end
