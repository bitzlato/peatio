# frozen_string_literal: true

RSpec.describe Workers::AMQP::WithdrawalProcessor do
  let(:member) { create(:member) }
  let(:withdrawal) { create(:eth_withdraw, member: member) }
  let(:private_key) { 'LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBd0lodXNUZnlCSVhNYUg2QUtwNkp5U1FkTEFLUHpudXpnelQraCtwT1BoT1lsTzk2CmN5R2tUK1JaS0lvMFFVMVBzUVFtbXlGZUhjcEFYYW9QSFd2cWhIUjJNRW54T01UWUNueU5YOGxYWkJMbTFIZUkKM2lSemk0MnppNmZ2SlVLQUVJOTREYlc5TXFoRG04aGRFV3VGMGhUOCtmR1d0bmZ2SEFnaGd3c0RMNGZPSENoNgpNTVJYT1lZUGF0Rlc4N0FQSWpNMk5mQW9rOEJQYjRZVVdsTHVNNUhSRS9yMnpzOHFXNjU5dGZSYWEyY2pOOEJxCjJEUklCZ0JFakZjMFlBSmtTQXVPN2N2QUVQdm8vZnR3d2F5bjA0NHdveGdOMVptbmhBaTJtanhxeTU2RVZqQU4KZGhTODZlTjE0SmJtK09HVG94WWJQNkh3RncwS3pFK3RUdTZhcHdJREFRQUJBb0lCQVFDci9UUmt1MFZISlA3awptWnlFZGZzLzR6THNEWjNKSmxmRjdhRXlhT3hjSjhVMXhuZnNRVEUyN1JWNFVYMDhtSU9IN2QxTzF3L3NMTEF5Cis2ZGs4UEllUUtzVGwvb1ViRU5SbXRIdnJ6eVIrUkNhMiswNEEvZnp3akdSb0FMUmxnWXd4UGpKeG4rc3NRTTAKTmxodEowL3p5eXZ4V3c3M0VVeFlEaXRobElUVC96NjVpZDB3eTF0cGpnTkJEY1A1QTQwL2taZ0pzZHZJaWJYeQovaHpuVWhPdnlnQzJIVFFqRzdScXV0MGM0SjNvNlN2U1pEUmdKS1FtWGxFUzliNHRXbTVja0FTc1NNanlkMUNKClQ0VDNUVmFRWndDSFE0eWNBdGxwK3VGNmg2VEJiTXdJQ1YxRENDYVJ0cGJlRVJYdWxWNXgrb0VKanZXSFNlbFoKMXYwRUJjTUJBb0dCQVBLZFZ2TVpCZ0piK2FMaXR2TWdnSEJHUVl5ZHN6bldMaElSOXFqY3BXT091N3dMcUxPVwpyV2hkRkFlenFxWjZLQ1VVU3JQbzZBN2hnUS82dVNiWDcvUkQrTDBsSDgyUEhZbk9vS3JQSFM2NUdZWVB6SkwvCmxnSUJDWE5CSDI1aVJBY0dTaEJWa09WTytCaVZMWlFMSHZ1U1ltQ1dRakFqR1RCYk9EZU84L2JmQW9HQkFNc24KdnI5d0FGTVlSd2g4amZNRE4vMG9XYXFZUThQZ2RhRi93VTRWQS9nek9Wd0x3anNhSGlnZFVpZEQyc01WUHk2Uwp4ZThxekU4MEJLbytWSEg4cWtkNTFLK0VkNmswam9kN1ZmUUdOZHVmaWU1eTBFRmxwMWIwbWNPMWtQMTl4cnhVCk5teThjVENPakZDdVBJZDVPRW1JY1M0RDZIYmgrV0N2NnhLUDVyMDVBb0dBUWw5Szd6eDBTV2J5RjE2Z29Fak8KK21ndC9KTVQrZ21mRnZCMUkyTWhsK2Z2Y2hWYWRLOFBCNU1YTExnNVFrdisrWTNnbGZGc3NzMThhbXUwQlcxagp4dFpsa1JFNzd4ZHRCRXRUNXdhOFBCRUZhNGljOWNZWU9yb2Y1TGozS1ZLV3U3azd2OVk0eXBMZENwU2RJSGdlClpNSjZTV1F4L1V0TTA4N1F4VnBGWWM4Q2dZQlhtaGZpclFVMno2MHh0NlB1T21FV1JTUUZNQXRvbDQyaHlsa3MKdGxzejE4TFFNakhiRW5RV2tDNHd5RTI0K1p4NUZNbE5USU0xVkJUKzVFbTlyVm92NEJVYWFtQy9FZTZ6OVRjbgpOdFpha2YwRVdYWDcvVDJmZlhJZ3RsYURPSTFPQUhKSGlTcTE2WUlQK0ZJWmlPZ0FyVmxBb21iSGZNSHdNMnVHCllZNzU0UUtCZ1FDbzk3RGwvNVFrcTFtTGpWeE1vSDZNN0l5R3kxdVdCT0pLMWxHRzBRUkgrN3pLWEcyTCt1NHQKTjNnQ3pNdjMxMk9Ocll4ck9YVHNxcDR4RFRGZE1ucXVQNE12cDNIS3FmT2RnM1NsdUpQK2N4S3VtUEY1SDVZLwpWSFNpeExWQ29OVVFST2VyeXhuL0JXYTZFTGpCYmk0UVlWQWlTWEo3L3Jpck91eHc2dTVHN0E9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=' } # rubocop:disable Layout/LineLength

  let(:payload) { data.merge('signature' => JWT.encode(data.merge(iat: Time.zone.now.to_i, exp: (Time.zone.now + 60).to_i), OpenSSL::PKey.read(Base64.urlsafe_decode64(private_key)), 'RS256')) }

  before do
    create(:account, :eth, member: member, balance: 100)
    withdrawal.accept!
  end

  around do |example|
    ENV['BELOMOR_JWT_PUBLIC_KEY'] = 'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF3SWh1c1RmeUJJWE1hSDZBS3A2Sgp5U1FkTEFLUHpudXpnelQraCtwT1BoT1lsTzk2Y3lHa1QrUlpLSW8wUVUxUHNRUW1teUZlSGNwQVhhb1BIV3ZxCmhIUjJNRW54T01UWUNueU5YOGxYWkJMbTFIZUkzaVJ6aTQyemk2ZnZKVUtBRUk5NERiVzlNcWhEbThoZEVXdUYKMGhUOCtmR1d0bmZ2SEFnaGd3c0RMNGZPSENoNk1NUlhPWVlQYXRGVzg3QVBJak0yTmZBb2s4QlBiNFlVV2xMdQpNNUhSRS9yMnpzOHFXNjU5dGZSYWEyY2pOOEJxMkRSSUJnQkVqRmMwWUFKa1NBdU83Y3ZBRVB2by9mdHd3YXluCjA0NHdveGdOMVptbmhBaTJtanhxeTU2RVZqQU5kaFM4NmVOMTRKYm0rT0dUb3hZYlA2SHdGdzBLekUrdFR1NmEKcHdJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg==' # rubocop:disable Layout/LineLength

    example.run
    ENV.delete('BELOMOR_JWT_PUBLIC_KEY')
  end

  context 'when event has confirming status' do
    let(:txid) { '0x0' }
    let(:data) { { 'remote_id' => withdrawal.id, 'status' => 'confirming', 'txid' => txid, 'owner_id' => "user:#{member.uid}" } }

    it 'dispatches withdrawal' do
      described_class.new.process(payload)
      expect(withdrawal.reload).to have_attributes(aasm_state: 'confirming', txid: txid)
    end
  end

  context 'when withdrawal is in confirming and event has succeed status' do
    let(:data) { { 'remote_id' => withdrawal.id, 'status' => 'succeed', 'owner_id' => "user:#{member.uid}", 'currency' => withdrawal.currency_id, 'amount' => withdrawal.sum.to_s, 'blockchain_key' => withdrawal.blockchain.key } }

    it 'successes withdrawal' do
      withdrawal.transfer!
      withdrawal.update!(txid: '0x0')
      withdrawal.dispatch!
      described_class.new.process(payload)
      expect(withdrawal.reload).to have_attributes(aasm_state: 'succeed', is_locked: false)
    end
  end

  context 'when withdrawal is in processing and event has succeed status' do
    let(:txid) { '0x123' }
    let(:data) { { 'remote_id' => withdrawal.id, 'status' => 'succeed', 'owner_id' => "user:#{member.uid}", 'currency' => withdrawal.currency_id, 'amount' => withdrawal.sum.to_s, 'blockchain_key' => withdrawal.blockchain.key, 'txid' => txid } }

    it 'successes withdrawal' do
      described_class.new.process(payload)
      expect(withdrawal.reload).to have_attributes(aasm_state: 'succeed', is_locked: false, txid: txid)
    end
  end

  context 'when event has errored status' do
    let(:data) { { 'remote_id' => withdrawal.id, 'status' => 'errored' } }

    it 'transits withdrawal to errored status' do
      described_class.new.process(payload)
      expect(withdrawal.reload).to have_attributes(aasm_state: 'errored', error: [{ 'class' => 'Workers::AMQP::WithdrawalProcessor::ErroredStatusError', 'message' => 'Errored withdrawal status' }])
    end
  end
end
