require 'peatio/owhdwallet/wallet'
require 'peatio/opendax_cloud/wallet'
require 'peatio/bitzlato/wallet'
Peatio::Wallet.registry[:bitcoind] = Bitcoin::Wallet
Peatio::Wallet.registry[:geth] = Ethereum::Wallet
Peatio::Wallet.registry[:parity] = Ethereum::Wallet
Peatio::Wallet.registry[:gnosis] = Gnosis::Wallet
Peatio::Wallet.registry[:ow_hdwallet] = OWHDWallet::Wallet
Peatio::Wallet.registry[:opendax] = OWHDWallet::Wallet
Peatio::Wallet.registry[:opendax_cloud] = OpendaxCloud::Wallet
Peatio::Wallet.registry[:bitzlato] = Bitzlato::Wallet
Peatio::Wallet.registry[:dummy] = Dummy::Wallet
Peatio::Wallet.registry[:tron] = Tron::Wallet
