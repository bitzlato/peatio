# frozen_string_literal: true

describe AMQP::Queue do
  let(:config) do
    Hashie::Mash.new(connect: { host: '127.0.0.1' },
                     exchange: { testx: { name: 'testx', type: 'fanout' } },
                     queue: { testq: { name: 'testq', durable: true },
                              testd: { name: 'testd' } },
                     binding: {
                       test: { queue: 'testq', exchange: 'testx' },
                       testd: { queue: 'testd' },
                       default: { queue: 'testq' }
                     })
  end

  let(:default_exchange) { stub('default_exchange') }
  let(:channel) { stub('channel', default_exchange: default_exchange) }

  before do
    AMQP::Config.stubs(:data).returns(config)

    described_class.unstub(:publish)
    described_class.stubs(:exchanges).returns(default: default_exchange)
    described_class.stubs(:channel).returns(channel)
  end

  it 'instantiates exchange use exchange config' do
    channel.expects(:fanout).with('testx')
    described_class.exchange(:testx)
  end

  it 'publishes message on selected exchange' do
    exchange = mock('test exchange')
    channel.expects(:fanout).with('testx').returns(exchange)
    exchange.expects(:publish).with(JSON.dump(data: 'hello'), {})
    described_class.publish(:testx, data: 'hello')
  end

  it 'publishes message on default exchange' do
    default_exchange.expects(:publish).with(JSON.dump(data: 'hello'), routing_key: 'testd')
    described_class.enqueue(:testd, data: 'hello')
  end
end
