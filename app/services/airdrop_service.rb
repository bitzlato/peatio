# Make an incentive airdrop deposit
#
class AirdropService
  CONFIG_FILE = "#{Rails.root}/config/airdrops.yml"

  class << self
    def config
      @config ||= YAML.load_file CONFIG_FILE
    end

    def currencies
      Currency.where(id: config['currencies'].keys)
    end

    def get_amount(currency_id)
      config['currencies'].fetch(currency_id.downcase)
    end
  end

  def initialize(member)
    @member = member
  end

  def perform
    self.class.currencies.each do |currency|
      wallet = Wallet.deposit_wallet(currency.id) || raise("No deposit wallet found for currency #{currency.id}")
      wallet.service.create_incentive_deposit!(
        member: @member,
        currency: currency,
        amount: self.class.get_amount(currency.id)
      )
    end
  end
end
