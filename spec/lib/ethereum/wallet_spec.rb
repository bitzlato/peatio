# frozen_string_literal: true

describe 'Ethereum::Eth::Wallet' do
  pending

  # let(:wallet) { Ethereum::Eth::Wallet.new }

  # context :configure do
  # let(:settings) { { wallet: {}, currency: {} } }
  # it 'requires wallet' do
  # expect { wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

  # expect { wallet.configure(settings) }.to_not raise_error
  # end

  # it 'requires currency' do
  # expect { wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

  # expect { wallet.configure(settings) }.to_not raise_error
  # end

  # it 'sets settings attribute' do
  # wallet.configure(settings)
  # expect(wallet.settings).to eq(settings.slice(*Ethereum::Eth::Wallet::SUPPORTED_SETTINGS))
  # end
  # end
end
