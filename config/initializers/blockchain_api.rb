Peatio::Blockchain.registry[:bitcoin] = Bitcoin::Blockchain
Peatio::Blockchain.registry[:geth] = Ethereum::Blockchain
Peatio::Blockchain.registry[:parity] = Ethereum::Blockchain
Peatio::Blockchain.registry[:dummy] = Dummy::Blockchain
Peatio::Blockchain.registry[:tron] = Tron::Blockchain
