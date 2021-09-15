# frozen_string_literal: true

RSpec.describe Peatio::Upstream::Opendax do
  let(:upstream_opendax_config) do
    {
      driver: 'opendax',
      source: 'btc_usd',
      target: 'btc_usd',
      rest: 'http://localhost',
      websocket: 'wss://localhost'
    }.stringify_keys
  end

  let(:opendax) { described_class.new(upstream_opendax_config) }

  let(:msg) do
    {
      'btc_usd.trades' =>
      { 'trades' =>
        [{ 'tid' => 247_646_537,
           'taker_type' => 'buy',
           'date' => 1_584_437_804,
           'price' => '5194.0',
           'amount' => '0.01710500' }] }
    }
  end

  let(:subscribe_msg) do
    {
      'success' =>
      { 'message' => 'subscribed',
        'streams' => ['btc_usd.trades'] }
    }
  end

  let(:trade) do
    {
      tid: 247_646_537,
      amount: '0.01710500',
      price: '5194.0',
      date: 1_584_437_804,
      taker_type: 'buy'
    }.stringify_keys
  end

  it 'detects trade' do
    opendax.expects(:notify_public_trade).with(trade)
    opendax.ws_read_public_message(msg)
  end

  it 'doesnt notify about public trade' do
    opendax.expects(:notify_public_trade).never
    opendax.ws_read_public_message(subscribe_msg)
  end
end
