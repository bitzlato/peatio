# frozen_string_literal: true

describe API::V2::Management::Exceptions::Base do
  it do
    expect(described_class.new(message: 'Wrong argument.').inspect).to eq \
      '#<API::V2::Management::Exceptions::Base: Wrong argument.>'
    expect(described_class.new(message: 'Wrong argument.', debug_message: 'Debug message.').inspect).to eq \
      '#<API::V2::Management::Exceptions::Base: Wrong argument. (Debug message.)>'
  end
end
