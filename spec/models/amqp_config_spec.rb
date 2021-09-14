# frozen_string_literal: true

module Workers
  module AMQP
    class Test # rubocop:disable Lint/EmptyClass
    end
  end
end

describe AMQP::Config do
  let(:config) do
    Hashie::Mash.new(connect: { host: '127.0.0.1' },
                     exchange: { testx: { name: 'testx', type: 'fanout' },
                                 testd: { name: 'testd', type: 'direct' },
                                 topicx: { name: 'topicx', type: 'topic' } },
                     queue: { testq: { name: 'testq', durable: true } },
                     binding: {
                       test: { queue: 'testq', exchange: 'testx' },
                       testd: { queue: 'testq', exchange: 'testd' },
                       topic: { queue: 'testq', exchange: 'topicx', topics: 'test.a,test.b' },
                       default: { queue: 'testq' }
                     })
  end

  before do
    described_class.stubs(:data).returns(config)
  end

  it 'tells client how to connect' do
    expect(described_class.connect).to eq({ 'host' => '127.0.0.1' })
  end

  it 'returns queue settings' do
    expect(described_class.queue(:testq)).to eq ['testq', { durable: true }]
  end

  it 'returns exchange settings' do
    expect(described_class.exchange(:testx)).to eq %w[fanout testx]
  end

  it 'returns binding queue' do
    expect(described_class.binding_queue(:test)).to eq ['testq', { durable: true }]
  end

  it 'returns binding exchange' do
    expect(described_class.binding_exchange(:test)).to eq %w[fanout testx]
  end

  it 'sets exchange to nil when binding use default exchange' do
    expect(described_class.binding_exchange(:default)).to be_nil
  end

  it 'finds binding worker' do
    expect(described_class.binding_worker(:test)).to be_instance_of(Workers::AMQP::Test)
  end

  it 'returns queue name of binding' do
    expect(described_class.routing_key(:testd)).to eq 'testq'
  end

  it 'returns topics to subscribe' do
    expect(described_class.topics(:topic)).to eq ['test.a', 'test.b']
  end
end
