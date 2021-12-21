# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::SunRefueler do
  include_context 'shared tron'

  describe '#refuel_sun!' do
    it 'return nil when enought amount on balance' do
      gateway.stubs(:required_sun_balance_to_collect).with(payment_address.address).returns(fee_currency.to_money_from_units(0))
      gateway.stubs(:fetch_balance).with(payment_address.address).returns(fee_currency.to_money_from_units(1))

      tx = gateway.refuel_sun!(payment_address)

      expect(tx).to be nil
    end

    it 'return balance with required amount' do
      VCR.use_cassette('tron/refuel_sun', record: :once) do
        required_amount = 20_000

        gateway.stubs(:required_sun_balance_to_collect).with(payment_address.address).returns(fee_currency.to_money_from_units(required_amount))
        gateway.stubs(:fetch_balance).with(payment_address.address).returns(fee_currency.to_money_from_units(10_000))
        tx = gateway.refuel_sun!(payment_address)

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.amount).to eq(20_000)
      end
    end
  end
end
