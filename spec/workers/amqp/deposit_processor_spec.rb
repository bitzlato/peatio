# frozen_string_literal: true

RSpec.describe Workers::AMQP::DepositProcessor do
  let(:member) { create(:member) }
  let(:blockchain) { find_or_create(:blockchain, 'eth-rinkeby', key: 'eth-rinkeby') }
  let(:currency) { find_or_create(:currency, 'eth', id: 'eth') }
  let(:txid) { '0x9b9a804676abb75d4afd4a961ead163ea1b96d00766ff24fb382aff2596ae150' }
  let(:txout) { nil }
  let(:amount) { 0.01.to_d }
  let(:to_address) { '0x8fd25c67f3ecbc7014efa111142a4b4557bb3dd9' }
  let(:from_address) { '0x702ad5C5FB87aACe54978143A707D565853d6Fd5' }
  let(:private_key) { 'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBd0lodXNUZnlCSVhNYUg2QUtwNkp5U1FkTEFLUHpudXpnelQraCtwT1BoT1lsTzk2CmN5R2tUK1JaS0lvMFFVMVBzUVFtbXlGZUhjcEFYYW9QSFd2cWhIUjJNRW54T01UWUNueU5YOGxYWkJMbTFIZUkKM2lSemk0MnppNmZ2SlVLQUVJOTREYlc5TXFoRG04aGRFV3VGMGhUOCtmR1d0bmZ2SEFnaGd3c0RMNGZPSENoNgpNTVJYT1lZUGF0Rlc4N0FQSWpNMk5mQW9rOEJQYjRZVVdsTHVNNUhSRS9yMnpzOHFXNjU5dGZSYWEyY2pOOEJxCjJEUklCZ0JFakZjMFlBSmtTQXVPN2N2QUVQdm8vZnR3d2F5bjA0NHdveGdOMVptbmhBaTJtanhxeTU2RVZqQU4KZGhTODZlTjE0SmJtK09HVG94WWJQNkh3RncwS3pFK3RUdTZhcHdJREFRQUJBb0lCQVFDci9UUmt1MFZISlA3awptWnlFZGZzLzR6THNEWjNKSmxmRjdhRXlhT3hjSjhVMXhuZnNRVEUyN1JWNFVYMDhtSU9IN2QxTzF3L3NMTEF5Cis2ZGs4UEllUUtzVGwvb1ViRU5SbXRIdnJ6eVIrUkNhMiswNEEvZnp3akdSb0FMUmxnWXd4UGpKeG4rc3NRTTAKTmxodEowL3p5eXZ4V3c3M0VVeFlEaXRobElUVC96NjVpZDB3eTF0cGpnTkJEY1A1QTQwL2taZ0pzZHZJaWJYeQovaHpuVWhPdnlnQzJIVFFqRzdScXV0MGM0SjNvNlN2U1pEUmdKS1FtWGxFUzliNHRXbTVja0FTc1NNanlkMUNKClQ0VDNUVmFRWndDSFE0eWNBdGxwK3VGNmg2VEJiTXdJQ1YxRENDYVJ0cGJlRVJYdWxWNXgrb0VKanZXSFNlbFoKMXYwRUJjTUJBb0dCQVBLZFZ2TVpCZ0piK2FMaXR2TWdnSEJHUVl5ZHN6bldMaElSOXFqY3BXT091N3dMcUxPVwpyV2hkRkFlenFxWjZLQ1VVU3JQbzZBN2hnUS82dVNiWDcvUkQrTDBsSDgyUEhZbk9vS3JQSFM2NUdZWVB6SkwvCmxnSUJDWE5CSDI1aVJBY0dTaEJWa09WTytCaVZMWlFMSHZ1U1ltQ1dRakFqR1RCYk9EZU84L2JmQW9HQkFNc24KdnI5d0FGTVlSd2g4amZNRE4vMG9XYXFZUThQZ2RhRi93VTRWQS9nek9Wd0x3anNhSGlnZFVpZEQyc01WUHk2Uwp4ZThxekU4MEJLbytWSEg4cWtkNTFLK0VkNmswam9kN1ZmUUdOZHVmaWU1eTBFRmxwMWIwbWNPMWtQMTl4cnhVCk5teThjVENPakZDdVBJZDVPRW1JY1M0RDZIYmgrV0N2NnhLUDVyMDVBb0dBUWw5Szd6eDBTV2J5RjE2Z29Fak8KK21ndC9KTVQrZ21mRnZCMUkyTWhsK2Z2Y2hWYWRLOFBCNU1YTExnNVFrdisrWTNnbGZGc3NzMThhbXUwQlcxagp4dFpsa1JFNzd4ZHRCRXRUNXdhOFBCRUZhNGljOWNZWU9yb2Y1TGozS1ZLV3U3azd2OVk0eXBMZENwU2RJSGdlClpNSjZTV1F4L1V0TTA4N1F4VnBGWWM4Q2dZQlhtaGZpclFVMno2MHh0NlB1T21FV1JTUUZNQXRvbDQyaHlsa3MKdGxzejE4TFFNakhiRW5RV2tDNHd5RTI0K1p4NUZNbE5USU0xVkJUKzVFbTlyVm92NEJVYWFtQy9FZTZ6OVRjbgpOdFpha2YwRVdYWDcvVDJmZlhJZ3RsYURPSTFPQUhKSGlTcTE2WUlQK0ZJWmlPZ0FyVmxBb21iSGZNSHdNMnVHCllZNzU0UUtCZ1FDbzk3RGwvNVFrcTFtTGpWeE1vSDZNN0l5R3kxdVdCT0pLMWxHRzBRUkgrN3pLWEcyTCt1NHQKTjNnQ3pNdjMxMk9Ocll4ck9YVHNxcDR4RFRGZE1ucXVQNE12cDNIS3FmT2RnM1NsdUpQK2N4S3VtUEY1SDVZLwpWSFNpeExWQ29OVVFST2VyeXhuL0JXYTZFTGpCYmk0UVlWQWlTWEo3L3Jpck91eHc2dTVHN0E9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=' } # rubocop:disable Layout/LineLength
  let(:payload) { data.merge('signature' => JWT.encode(data.merge(iat: Time.zone.now.to_i, exp: (Time.zone.now + 60).to_i), OpenSSL::PKey.read(Base64.urlsafe_decode64(private_key)), 'RS256')) }

  around do |example|
    ENV['BELOMOR_JWT_PUBLIC_KEY'] = 'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF3SWh1c1RmeUJJWE1hSDZBS3A2Sgp5U1FkTEFLUHpudXpnelQraCtwT1BoT1lsTzk2Y3lHa1QrUlpLSW8wUVUxUHNRUW1teUZlSGNwQVhhb1BIV3ZxCmhIUjJNRW54T01UWUNueU5YOGxYWkJMbTFIZUkzaVJ6aTQyemk2ZnZKVUtBRUk5NERiVzlNcWhEbThoZEVXdUYKMGhUOCtmR1d0bmZ2SEFnaGd3c0RMNGZPSENoNk1NUlhPWVlQYXRGVzg3QVBJak0yTmZBb2s4QlBiNFlVV2xMdQpNNUhSRS9yMnpzOHFXNjU5dGZSYWEyY2pOOEJxMkRSSUJnQkVqRmMwWUFKa1NBdU83Y3ZBRVB2by9mdHd3YXluCjA0NHdveGdOMVptbmhBaTJtanhxeTU2RVZqQU5kaFM4NmVOMTRKYm0rT0dUb3hZYlA2SHdGdzBLekUrdFR1NmEKcHdJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==' # rubocop:disable Layout/LineLength

    example.run
    ENV.delete('BELOMOR_JWT_PUBLIC_KEY')
  end

  context 'with sumbitted event status' do
    let(:data) do
      {
        owner_id: "user:#{member.uid}",
        to_address: to_address,
        from_address: from_address,
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        status: 'submitted'
      }.stringify_keys
    end

    it 'creates deposit' do
      described_class.new.process(payload)
      expect(Deposit.find_by(blockchain: blockchain, txid: txid)).to have_attributes(currency_id: currency.id, amount: amount, txout: txout, member: member, aasm_state: 'accepted', address: to_address, from_addresses: [from_address])
    end
  end

  context 'when deposit exists and with succeed event status' do
    let(:data) do
      {
        owner_id: "user:#{member.uid}",
        to_address: to_address,
        from_address: from_address,
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        status: 'succeed'
      }.stringify_keys
    end

    it 'dispatches deposit' do
      deposit = create(:deposit, :deposit_eth, blockchain: blockchain, currency: currency, txid: txid, txout: txout, amount: amount, member: member, aasm_state: 'submitted')
      described_class.new.process(payload)
      expect(deposit.reload).to have_attributes(aasm_state: 'dispatched')
    end
  end

  context 'when deposit does not exist and with succeed event status' do
    let(:data) do
      {
        owner_id: "user:#{member.uid}",
        to_address: to_address,
        from_address: from_address,
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        status: 'succeed'
      }.stringify_keys
    end

    it 'creates and dispatches deposit' do
      described_class.new.process(payload)
      expect(Deposit.find_by!(blockchain: blockchain, txid: txid)).to have_attributes(aasm_state: 'dispatched')
    end
  end

  context 'with aml_check event status' do
    let(:data) do
      {
        owner_id: "user:#{member.uid}",
        to_address: to_address,
        from_address: from_address,
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        status: 'aml_check'
      }.stringify_keys
    end

    it 'creates and aml_check deposit' do
      Peatio::App.config.stubs(:deposit_funds_locked).returns(true)
      described_class.new.process(payload)
      deposit = Deposit.find_by!(blockchain: blockchain, txid: txid)
      expect(deposit).to have_attributes(aasm_state: 'aml_check')
      expect(deposit.member.accounts.take.locked).to eq deposit.amount
    end
  end

  context 'with incorrect payload' do
    let(:data) do
      {
        owner_id: "user:#{member.uid}",
        to_address: to_address,
        from_address: from_address,
        amount: amount.to_s,
        txid: txid,
        txout: txout,
        blockchain_key: blockchain.key,
        currency: currency.id,
        status: 'succeed'
      }.stringify_keys
    end
    let(:payload) { data.merge('signature' => JWT.encode(data.merge(amount: 100.to_s, iat: Time.zone.now.to_i, exp: (Time.zone.now + 60).to_i), OpenSSL::PKey.read(Base64.urlsafe_decode64(private_key)), 'RS256')) }

    it 'skips message' do
      described_class.new.process(payload)
      expect(Deposit.find_by(blockchain: blockchain, txid: txid)).to eq nil
    end
  end
end
