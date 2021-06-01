describe Bitzlato::Wallet do
  let(:wallet) { Bitzlato::Wallet.new }

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
      {"kty":"EC","alg":"ES256","crv":"P-256",
       "x":"wwf6h_sZhv6TXAYz4XrdXZVpLo_uoNESbaEf_zEydus",
       "y":"OL-0AqcTNoaCBVAEpDNsU1bpZA7eQ9CtGPZGmEEg5QI",
       "d":"nDTvKjSPQ4UAPiBmJKXeF1MKhuhLtjJtW6hypstWolk"}
    }

    let(:withdraw_method) { 'voucher' }

    let(:settings) do
      {
        wallet: { uri: uri, key: key, uid: 'merchant_uid', withdraw_method: withdraw_method, withdraw_polling_methods: ['vouchers', 'payments'] },
        currency: { id: :btc },
      }
    end

    context :poll_payments do
      let(:response) do
          [
            {
              "publicName": "dapi",
              "links": nil,
              "amount": 0.21,
              "cryptocurrency": "BTC",
              "type": "auto",
              "status": "done",
              "date": 1616396531426
            },
            {
              "publicName": "dapi",
              "links": nil,
              "amount": 0.2,
              "cryptocurrency": "BTC",
              "type": "auto",
              "status": "done",
              "date": 1616396505639
            },
            {
              "publicName": "dapi",
              "links": nil,
              "amount": 0.19,
              "cryptocurrency": "BTC",
              "type": "auto",
              "status": "done",
              "date": 1616396365270
            }
          ]
      end

      it do
        stub_request(:get, "http://127.0.0.1:8000/api/gate/v1/payments/list/")
          .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })
        payments = wallet.send :poll_payments
        expect(payments.count).to eq 3
        expect(payments.second.is_done).to be_truthy
      end
    end

    context :poll_vouchers do
      let(:response) do
        {
          "total": 2,
          "data": [
            {
              "deepLinkCode": "c_c8e8f34d2fff9f5dbc222939feeefbe5",
              "currency": {
                "code": "USD",
                "amount": "5385"
              },
              "cryptocurrency": {
                "code": "BTC",
                "amount": "1"
              },
              "createdAt": 1616127762606,
              "links": [
                {
                  "type": "telegram bot @BTC_STAGE_BOT",
                  "url": "https://telegram.me/BTC_STAGE_BOT?start=c_c8e8f34d2fff9f5dbc222939feeefbe5"
                },
                {
                  "type": "web exchange",
                  "url": "https://s-www.lgk.one/p2p/?start=c_c8e8f34d2fff9f5dbc222939feeefbe5"
                }
              ],
              "status": "none",
              "cashedBy": "EasySammieFrey"
            },
            {
              "deepLinkCode": "c_c8e8f34d2fff9f5dbc222939feeefbe5",
              "currency": {
                "code": "USD",
                "amount": "5385"
              },
              "cryptocurrency": {
                "code": "BTC",
                "amount": "0.0931216"
              },
              "createdAt": 1616127762606,
              "links": [
                {
                  "type": "telegram bot @BTC_STAGE_BOT",
                  "url": "https://telegram.me/BTC_STAGE_BOT?start=c_c8e8f34d2fff9f5dbc222939feeefbe5"
                },
                {
                  "type": "web exchange",
                  "url": "https://s-www.lgk.one/p2p/?start=c_c8e8f34d2fff9f5dbc222939feeefbe5"
                }
              ],
              "status": "cashed",
              "cashedBy": "EasySammieFrey"
            },
          ] }
      end

      it do
        stub_request(:get, "http://127.0.0.1:8000/api/p2p/vouchers/")
          .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })
        vouchers = wallet.send :poll_vouchers
        expect(vouchers.count).to eq 2
        expect(vouchers.first.is_done).to be_falsey
        expect(vouchers.second.is_done).to be_truthy
      end
    end

    context :poll_withdraws do
      it do
        wallet.expects(:poll_vouchers).returns []
        wallet.expects(:poll_payments).returns []
        withdraws = wallet.poll_withdraws

        expect(withdraws).to be_a Array
      end
    end


    context :create_transaction! do
      let(:source_transaction) {
        Peatio::Transaction.new(to_address: 1,
                                amount:     123,
                                currency_id: 'BTC',
                                options: { withdrawal_id: 12, tid: 'tid' })
      }

      context :voucher do
        let(:withdraw_method) { 'voucher' }
        it 'create withdrawal transaction' do
          wallet.expects(:create_voucher!)
          wallet.create_transaction!(source_transaction)
        end
      end

      context :payment do
        let(:withdraw_method) { 'payment' }
        it 'create withdrawal transaction' do
          wallet.expects(:create_payment!)
          wallet.create_transaction!(source_transaction)
        end
      end

      context :create_payment! do
        let(:response) { { paymentId: 12 }}
        it 'show create withdrawal transaction' do
          stub_request(:post, uri + '/api/gate/v1/payments/create')
            .with( body: "{\"clientProvidedId\":12,\"client\":1,\"cryptocurrency\":\"BTC\",\"amount\":123,\"payedBefore\":true}" )
            .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })

          transaction = wallet.create_payment!(source_transaction)

          expect(transaction).to be_a Peatio::Transaction
          expect(transaction.txout).to be_present
          expect(transaction.hash).to be_present
        end
      end

      context :create_voucher! do
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

        it 'create voucher' do
          stub_request(:post, uri + '/api/p2p/vouchers/')
            .with(body: {"cryptocurrency":"BTC","amount":123,"method":"crypto", 'currency': 'USD'}.to_json)
            .to_return(body: response.to_json, headers: { 'Content-Type': 'application/json' })


          transaction = wallet.create_voucher!(source_transaction)

          expect(transaction).to be_a Peatio::Transaction
          expect(transaction.txout).to be_present
          expect(transaction.hash).to be_present
          expect(transaction.options['voucher']).to be_present
          expect(transaction.options['links']).to be_a(Array)
          expect(transaction.options['links'].count).to eq(2)
          expect(transaction.options['links'].first.keys).to eq(['title', 'url'])
        end
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

        result = wallet.create_deposit_intention!(comment: 'Exchange service deposit for account uid12312', amount: 123)

        expect(result[:id]).to eq '0:21'
        expect(result[:amount]).to eq 1.1
        expect(result[:links]).to be_a(Array)
        expect(result[:links].count).to eq(2)
        expect(result[:links].first.keys).to eq(['title', 'url'])
        expect(result[:expires_at]).to be_a(Time)
      end
    end
  end
end
