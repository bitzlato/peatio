# frozen_string_literal: true

module API
  module V2
    module Management
      class MemberTransfers < Grape::API
        desc 'Creates new member transfer.' do
          @settings[:scope] = :write_transfers
        end
        params do
          requires :key,
                   type: String,
                   desc: 'Unique Transfer Key.'
          requires :description,
                   type: String,
                   desc: 'Transfer Description.'
          requires :currency_id,
                   type: String,
                   values: -> { Currency.codes(bothcase: true) },
                   desc: 'Operation currency.'
          requires :amount,
                   type: BigDecimal,
                   values: ->(v) { !v.to_d.zero? },
                   desc: 'Operation amount.'
          requires :service,
                   type: String,
                   values: MemberTransfer::AVAILABLE_SERVICES
          requires :member_uid
        end
        post '/member_transfers' do
          mt = MemberTransfer.create! declared(params).merge(meta: params)
          mt.process!
          present mt, with: Entities::MemberTransfer
          status 201
        rescue ActiveRecord::RecordInvalid => e
          body errors: e.message
          status 422
        rescue ::Account::AccountError => e
          body errors: "Account balance is insufficient (#{e.message})"
          status 422
        end
      end
    end
  end
end
