# frozen_string_literal: true

describe Peatio::InfluxDB do
  context 'host sharding' do
    before do
      described_class.instance_variable_set(:@clients, {})
      described_class.stubs(:config).returns({ host: %w[inflxudb-0 inflxudb-1] })
    end

    after do
      described_class.instance_variable_set(:@clients, {})
    end

    it do
      expect(described_class.client(keyshard: 'btc_usd').config.hosts).to eq(['inflxudb-1'])
      expect(described_class.client(keyshard: 'eth_usd').config.hosts).to eq(['inflxudb-0'])
    end
  end
end
