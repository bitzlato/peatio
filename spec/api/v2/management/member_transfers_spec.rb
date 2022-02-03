# frozen_string_literal: true

describe API::V2::Management::MemberTransfers, type: :request do
  before do
    defaults_for_management_api_v1_security_configuration!
    management_api_v1_security_configuration.merge! \
      scopes: {
        read_transfers: { permitted_signers: %i[alex jeff], mandatory_signers: %i[alex] },
        write_transfers: { permitted_signers: %i[alex jeff james], mandatory_signers: %i[alex jeff] }
      }
  end

  describe 'create operation' do
    def request
      post_json '/api/v2/management/member_transfers', multisig_jwt_management_api_v1({ data: data }, *signers)
    end

    let(:currency) { Currency.coins.sample }
    let(:signers) { %i[alex jeff] }
    let(:member) { create(:member, :level_3) }
    let(:amount) { 100 }
    let(:data) do
      {
        key: generate(:transfer_key),
        currency_id: currency.id,
        service: MemberTransfer::AVAILABLE_SERVICES.first,
        description: "Referral program payoffs (#{Time.now.to_date})",
        amount: amount,
        member_uid: member.uid
      }
    end

    context 'automatically creates an account, if transfer will be send' do
      it do
        expect do
          request
          expect(response).to have_http_status(:created)
        end.to change { member.accounts.reload.count }.from(0).to(1)
      end
    end

    context 'empty key' do
      before do
        data.delete(:key)
        request
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/key is missing/i)
      end
    end

    context 'empty service' do
      before do
        data.delete(:service)
        request
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/service is missing/i)
      end
    end

    context 'empty description' do
      before do
        data.delete(:description)
        request
      end

      it { expect(response).to have_http_status(:unprocessable_entity) }
    end

    context 'invalid currency_id' do
      before do
        data[:currency_id] = :neo
        request
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/does not have a valid value/i)
      end
    end

    context 'invalid amount' do
      before do
        data[:amount] = 0
        request
      end

      it do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match(/does not have a valid value/i)
      end
    end

    context 'existing transfer key' do
      it 'raise error if attribute has been changed' do
        t = create(:member_transfer, :income)
        data[:key] = t.key
        request
        expect(response).to have_http_status(:internal_server_error)
      end

      it 'return success' do
        request
        expect(response).to have_http_status(:created)
        request
        expect(response).to have_http_status(:ok)
      end
    end

    context 'debit liability on account with insufficient balance' do
      let!(:deposit) { create(:deposit_btc, member: member, amount: 1) }

      before do
        data[:amount] = -1.1
        request
      end

      it do
        expect(response).to have_http_status :unprocessable_entity
        expect(response.body).to match(/account balance is insufficient/i)
      end
    end
  end
end
