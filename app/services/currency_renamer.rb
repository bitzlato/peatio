class CurrencyRenamer
  def self.rename_legacy
    # new.call(:bnb,  'bnb-bep20')
    # new.call(:usdc, 'usdc-erc20')
    new.call(:usdt, 'usdt-erc20')
    new.call(:mcr,  'mcr-erc20')
    new.call(:dai,  'dai-erc20')
    new.call(:mdt,  'mdt-erc20')
  end

  def call(old_id, new_id)
    Currency.transaction do
      puts "Rename #{old_id} to #{new_id}"
      old_currency = Currency.find(old_id)
      old_currency.dependent_markets.each do |m|
        puts "Cancel all orders (#{m.orders.active.count}) for #{old_id} on #{m}"
        m.orders.active.each do |order|
          Order.cancel order.id
        end
      end

      if new_currency = Currency.find_by(id: new_id)
        new_currency.dependent_markets.each do |m|
          puts "Cancel all orders (#{m.orders.active.count}) for #{new_id} on #{m}"
          m.orders.active.each do |order|
            Order.cancel order.id
          end
        end
      else
        puts "Create curency #{new_id}"
        Currency.create!(old_currency.attributes.merge(id: new_id))
      end
      puts 'Update currency parent_id'
      Currency.where(parent_id: old_id).update_all parent_id: new_id
      puts 'Delete old currency'
      old_currency.delete
      puts 'Update orders'

      Order.where(bid: old_id).update_all bid: new_id
      Order.where(ask: old_id).update_all ask: new_id

      puts 'Update markets'
      Market.where(base_unit: old_id).update_all base_unit: new_id
      Market.where(quote_unit: old_id).update_all quote_unit: new_id

      Market.where('base_unit = ? or quote_unit = ?', new_id, new_id).each do |m|
        m.update_column :symbol, m.send(:generate_symbol)
      end
      puts "Update currency_id in models"

      [
        Adjustment,
        Operations::Asset,
        Operations::Expense,
        Operations::Liability,
        Operations::Revenue,
        Beneficiary,
        DepositSpread,
        Deposit,
        Transaction,
        Withdraw,
        Account
      ].each do |model|
        puts "Move #{model} from #{old_id} to #{new_id}"
        model.where(currency_id: old_id).update_all currency_id: new_id
      end
      puts '---'
    end
  end
end
