# frozen_string_literal: true

describe API::V2::Management::Trades, type: :request do
  let(:member) do
    create(:member, :level_3).tap do |m|
      m.get_account(:btc).update(balance: 12.13,   locked: 3.14)
      m.get_account(:usd).update(balance: 2014.47, locked: 0)
    end
  end
  let(:data) { {} }
  let(:signers) { %i[alex jeff] }

  let(:second_member) do
    create(:member, :level_3).tap do |m|
      m.get_account(:btc).update(balance: 12.13,   locked: 3.14)
      m.get_account(:usd).update(balance: 2014.47, locked: 0)
    end
  end

  let(:btc_usd_ask) do
    create(
      :order_ask,
      :btc_usd,
      price: '12.32'.to_d,
      volume: '123.12345678',
      member: member
    )
  end

  let(:btc_eth_ask) do
    create(
      :order_ask,
      :btc_eth,
      price: '12.326'.to_d,
      volume: '123.1234',
      member: second_member
    )
  end

  let(:btc_usd_bid) do
    create(
      :order_bid,
      :btc_usd,
      price: '12.32'.to_d,
      volume: '123.12345678',
      member: member
    )
  end

  let(:btc_eth_bid) do
    create(
      :order_bid,
      :btc_eth,
      price: '12.326'.to_d,
      volume: '123.1234',
      member: second_member
    )
  end

  let!(:btc_usd_ask_trade) { create(:trade, :btc_usd, maker_order: btc_usd_ask, created_at: 2.days.ago) }
  let!(:btc_eth_ask_trade) { create(:trade, :btc_eth, maker_order: btc_eth_ask, created_at: 2.days.ago) }
  let!(:btc_usd_bid_trade) { create(:trade, :btc_usd, taker_order: btc_usd_bid, created_at: 23.hours.ago) }
  let!(:btc_eth_bid_trade) { create(:trade, :btc_eth, taker_order: btc_eth_bid, created_at: 23.hours.ago) }
  let!(:btc_eth_bid_qe_trade) { create(:trade, :btc_eth_qe, created_at: 23.hours.ago) }

  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
        read_trades: { permitted_signers: %i[alex jeff], mandatory_signers: %i[alex] }
      }
  end

  def request
    post_json '/api/v2/management/trades', multisig_jwt_management_api_v1({ data: data }, *signers)
  end

  it 'returns all recent spot trades' do
    request
    expect(response).to be_successful

    result = JSON.parse(response.body)
    expect(result.count).to eq 4
  end

  it 'returns all recent qe trades' do
    data[:market_type] = 'qe'
    request
    expect(response).to be_successful

    result = JSON.parse(response.body)
    expect(result.count).to eq 1
  end

  it 'returns trades by uid of user' do
    data.merge!(uid: member.uid)
    request
    expect(response).to be_successful

    result = JSON.parse(response.body)
    expect(result.count).to eq 2
  end

  it 'returns trades on spot market' do
    data.merge!(market: 'btc_usd')
    request
    expect(response).to be_successful

    result = JSON.parse(response.body)
    expect(result.count).to eq 2
  end

  it 'returns trades on qe market' do
    data.merge!(market: 'btc_eth', market_type: 'qe')
    request
    expect(response).to be_successful

    result = JSON.parse(response.body)
    expect(result.count).to eq 1
  end
end
