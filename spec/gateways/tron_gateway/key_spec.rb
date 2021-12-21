# frozen_string_literal: true

describe ::TronGateway::Key do
  subject { described_class.new(priv: private_key) }

  let(:private_key) { 'a9295ef051b88811cd898f0d092e62021bdbc203fa82c74716d749949a8cd579' }

  it 'return valid address' do
    expect(subject.base58check_address).to eq('TUGGVKRierZ3KcwPQqLBN5jCx9VmtPk156')
  end
end
