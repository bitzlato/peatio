require 'peatio/bitzlato/wallet'
Peatio::Wallet.registry[:bitcoind] = Bitcoin::Wallet
Peatio::Wallet.registry[:geth] = Ethereum::Eth::Wallet
Peatio::Wallet.registry[:parity] = Ethereum::Eth::Wallet
Peatio::Wallet.registry[:gnosis] = Gnosis::Wallet
if Rails.env.test?
  Peatio::Wallet.registry[:"ow-hdwallet-eth"] = OWHDWallet::WalletETH
  Peatio::Wallet.registry[:"ow-hdwallet-bsc"] = OWHDWallet::WalletBSC
  Peatio::Wallet.registry[:"ow-hdwallet-heco"] = OWHDWallet::WalletHECO
  Peatio::Wallet.registry[:opendax_cloud] = OpendaxCloud::Wallet
end
Peatio::Wallet.registry[:bitzlato] = Bitzlato::Wallet
Peatio::Wallet.registry[:dummy] = Dummy::Wallet
