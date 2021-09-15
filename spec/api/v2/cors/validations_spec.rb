# frozen_string_literal: true

describe CORS::Validations do
  describe 'validate origins' do
    subject { described_class.validate_origins(ENV['API_CORS_ORIGINS']) }

    context 'set API_CORS_ORIGINS as "*"' do
      before { ENV['API_CORS_ORIGINS'] = '*' }

      after { ENV['API_CORS_ORIGINS'] = nil }

      it { is_expected.to eq('*') }
    end

    context 'set mulitple API_CORS_ORIGINS with "*"' do
      before { ENV['API_CORS_ORIGINS'] = 'https://localhost,*,https://domain.com' }

      after { ENV['API_CORS_ORIGINS'] = nil }

      it { is_expected.to eq('*') }
    end

    context 'set multiple API_CORS_ORIGINS' do
      before { ENV['API_CORS_ORIGINS'] = 'https://localhost,https://domain.com' }

      after { ENV['API_CORS_ORIGINS'] = nil }

      it { is_expected.to eq(['https://localhost', 'https://domain.com']) }
    end

    context 'set invalid domain into API_CORS_ORIGINS' do
      before { ENV['API_CORS_ORIGINS'] = 'htt:://localhost' }

      after { ENV['API_CORS_MAX_AGE'] = nil }

      it { expect { subject }.to raise_error(CORS::Validations::Error) }
    end
  end

  describe 'validate max age' do
    subject { described_class.validate_max_age(ENV['API_CORS_MAX_AGE']) }

    context 'set API_CORS_MAX_AGE as "6200"' do
      before { ENV['API_CORS_MAX_AGE'] = '6200' }

      after { ENV['API_CORS_MAX_AGE'] = nil }

      it { is_expected.to eq('6200') }
    end

    context 'set API_CORS_MAX_AGE as "6200.1"' do
      before { ENV['API_CORS_MAX_AGE'] = '6200.1' }

      after { ENV['API_CORS_MAX_AGE'] = nil }

      it { is_expected.to eq('3600') }
    end

    context 'doesn\'t set API_CORS_MAX_AGE"' do
      before { ENV['API_CORS_MAX_AGE'] = nil }

      it { is_expected.to eq('3600') }
    end
  end
end
