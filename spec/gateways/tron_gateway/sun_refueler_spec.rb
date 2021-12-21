# frozen_string_literal: true

require './spec/gateways/shared_tron'

describe ::TronGateway::SunRefueler, :tron do
  describe '#refuel_sun!' do
    it 'return nil when enought amount on balance' do
      tron_gateway.stubs(:required_sun_balance_to_collect).with(tron_payment_address.address).returns(tron_fee_blockchain_currency.to_money_from_units(0))
      tron_gateway.stubs(:fetch_balance).with(tron_payment_address.address).returns(tron_fee_blockchain_currency.to_money_from_units(1))

      tx = tron_gateway.refuel_sun!(tron_payment_address)

      expect(tx).to be nil
    end

    it 'return balance with required amount' do
      VCR.use_cassette('tron/refuel_sun', record: :once) do
        required_amount = 20_000

        tron_gateway.stubs(:required_sun_balance_to_collect).with(tron_payment_address.address).returns(tron_fee_blockchain_currency.to_money_from_units(required_amount))
        tron_gateway.stubs(:fetch_balance).with(tron_payment_address.address).returns(tron_fee_blockchain_currency.to_money_from_units(10_000))
        tx = tron_gateway.refuel_sun!(tron_payment_address)

        expect(tx).to be_a(Peatio::Transaction)
        expect(tx.amount).to eq(20_000)
      end
    end
  end
end
