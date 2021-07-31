require 'peatio/bitzlato/wallet'
Peatio::Wallet.registry[:bitcoind] = Bitcoin::Wallet
Peatio::Wallet.registry[:geth] = Ethereum::Eth::Wallet
Peatio::Wallet.registry[:parity] = Ethereum::Eth::Wallet
Peatio::Wallet.registry[:bitzlato] = Bitzlato::Wallet
Peatio::Wallet.registry[:dummy] = Dummy::Wallet
