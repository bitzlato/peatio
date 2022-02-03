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
                   values: -> { Currency.codes },
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
          attributes = declared(params).merge(meta: params)
          mt = MemberTransfer.find_by_key(params[:key])
          if mt.present?
            mt.assign_attributes attributes
            raise "Member transfer (#{mt.key}) exists and attributes are changed (#{mt.changed_attributes})" if mt.changed?
            present mt, with: Entities::MemberTransfer
            status 200
          else
            MemberTransfer.transaction do
              mt = MemberTransfer.new attributes
              mt.save!

              account = mt.member.get_account(mt.currency_id)

              account.with_lock do
                if mt.amount.positive?
                  account.plus_funds!(mt.amount)
                  ::Operations::Asset.credit!(
                    amount: mt.amount,
                    currency: mt.currency,
                    reference: mt
                  )
                  ::Operations::Liability.credit!(
                    amount: mt.amount,
                    currency: mt.currency,
                    reference: mt,
                    member_id: mt.member_id,
                    kind: :main
                  )
                else
                  account.sub_funds!(-mt.amount)
                  ::Operations::Asset.debit!(
                    amount: -mt.amount,
                    currency: mt.currency,
                    reference: mt
                  )
                  ::Operations::Liability.debit!(
                    amount: -mt.amount,
                    currency: mt.currency,
                    reference: mt,
                    member_id: mt.member_id,
                    kind: :main
                  )
                end
              end
            end
          end

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
