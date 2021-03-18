describe Bitzlato::Wallet do
  let(:wallet) { Bitzlato::Wallet.new }

  context :configure do
    let(:settings) { { wallet: {}, currency: {} } }
    it 'requires wallet' do
      expect { wallet.configure(settings.except(:wallet)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it 'requires currency' do
      expect { wallet.configure(settings.except(:currency)) }.to raise_error(Peatio::Wallet::MissingSettingError)

      expect { wallet.configure(settings) }.to_not raise_error
    end

    it 'sets settings attribute' do
      wallet.configure(settings)
      expect(wallet.settings).to eq(settings.slice(*Ethereum::Wallet::SUPPORTED_SETTINGS))
    end
  end

  describe :requests do
    around do |example|
      WebMock.disable_net_connect!
      example.run
      WebMock.allow_net_connect!
    end

    before do
      wallet.configure(settings)
      ENV['BITZLATO_API_KEY']=nil
      ENV['BITZLATO_API_URL']=nil
      ENV['BITZLATO_API_CLIENT_UID']=nil
    end

    let(:uri) { 'http://127.0.0.1:8000' }
    let(:key) {
      {"kty":"EC","alg":"ES256","crv":"P-256","x":"wwf6h_sZhv6TXAYz4XrdXZVpLo_uoNESbaEf_zEydus","y":"OL-0AqcTNoaCBVAEpDNsU1bpZA7eQ9CtGPZGmEEg5QI","d":"nDTvKjSPQ4UAPiBmJKXeF1MKhuhLtjJtW6hypstWolk"}
    }

    let(:settings) do
      {
        wallet: { uri: uri, key: key, uid: 'merchant_uid' },
        currency: { id: :btc }
      }
    end

    context :create_transaction! do
      let(:response) do
        {
            "deepLinkCode"=>"someHash",
            "currency"=>{"code"=>"USD", "amount"=>"6965"},
            "cryptocurrency"=>{"code"=>"BTC", "amount"=>"0.12"},
            "createdAt"=>1616075809783,
            "links"=>[
              {"type"=>"telegram bot @BTC_STAGE_BOT", "url"=>"https://telegram.me/BTC_STAGE_BOT?start=someHash"},
              {"type"=>"web exchange", "url"=>"https://s-www.lgk.one/p2p/?start=someHash"}
            ],
            "status"=>"active",
            "cashedBy"=>nil,
            "comment"=>nil
        }
      end

      it 'show create withdrawal transaction' do
        stub_request(:post, uri + '/api/p2p/vouchers/')
          .with(body: {"cryptocurrency":"BTC","amount":123,"method":"crypto", 'currency': 'USD'}.to_json)
          .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })


        transaction = Peatio::Transaction.new(to_address: 1,
                                              amount:     123,
                                              currency_id: 'BTC',
                                              options: { tid: 'tid' })

        transaction = wallet.create_transaction!(transaction)

        expect(transaction).to be_a Peatio::Transaction
        expect(transaction.txout).to be_present
        expect(transaction.hash).to be_present
        expect(transaction.options['voucher']).to be_present
        expect(transaction.options['links']).to be_present
      end
    end

    context :create_deposit_intention! do
      let(:response) do
        {
          "id"=>21,
          "cryptocurrency"=>"BTC",
          "amount"=>"1.1",
          "comment"=>"gift from drew",
          "link"=>{"telegram"=>"https://t.me/BTC_STAGE_BOT?start=b_9ac6b97e09ecbbfc0d365421f6b98a33", "web"=>"https://s-www.lgk.one/p2p/?start=b_9ac6b97e09ecbbfc0d365421f6b98a33"},
          "createdAt"=>1615444044115,
          "expiryAt"=>1615530444115,
          "completedAt"=>nil,
          "status"=>"active"
        }
      end

      it 'should create an invoice' do
        stub_request(:post, uri + '/api/gate/v1/invoices/')
          .with(body: {"cryptocurrency":"BTC","amount":123,"comment":"Exchange service deposit for account uid12312"}.to_json)
          .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })

        result = wallet.create_deposit_intention!(account_id: 'uid12312', amount: 123)

        expect(result[:id]).to eq 21
        expect(result[:amount]).to eq 1.1
        expect(result[:links]).to be_a(Hash)
        expect(result[:expires_at]).to be_a(Time)
      end
    end
  end
end
