# frozen_string_literal: true

module API
  module V2
    module Management
      class PaymentAddress < Grape::API
        desc 'Create payment address' do
          @settings[:scope] = :write_payment_addresses
          success API::V2::Management::Entities::PaymentAddress
        end

        params do
          requires :uid,
                   type: String,
                   values: { value: ->(v) { Member.exists?(uid: v) }, message: 'management.payment_address.uid_doesnt_exist' },
                   desc: API::V2::Management::Entities::PaymentAddress.documentation[:uid][:desc]
          requires :currency,
                   type: String,
                   values: { value: -> { Currency.codes(bothcase: true) }, message: 'management.payment_address.currency_doesnt_exist' },
                   desc: -> { API::V2::Management::Entities::Currency.documentation[:code][:desc] }
          optional :remote,
                   type: { value: Boolean, message: 'management.payment_address.non_boolean_remote' },
                   desc: API::V2::Management::Entities::PaymentAddress.documentation[:remote][:desc]
        end

        post '/deposit_address/new' do
          member = Member.find_by(uid: params[:uid]) if params[:uid].present?

          currency = Currency.find(params[:currency])
          unless currency.deposit_enabled?
            error!({ errors: ['account.currency.deposit_disabled'] }, 422)
          end

          wallet = Wallet.active_deposit_wallet(currency.id)
          unless wallet.present?
            error!({ errors: ['account.wallet.not_found'] }, 422)
          end

          unless params[:remote].nil?
            pa = member.payment_address!(wallet.id, params[:remote])
          else
            pa = member.payment_address!(wallet.id)
          end

          begin
            pa.with_lock do
              next if pa.address.present?

              # Supply address ID in case of BitGo address generation if it exists.
              result = wallet.create_address!(member.uid, pa.details.merge(updated_at: pa.updated_at))
              if result.present?
                pa.update!(address: result[:address],
                          secret:  result[:secret],
                          details: result.fetch(:details, {}).merge(pa.details))
              end
            end

            present pa, with: API::V2::Management::Entities::PaymentAddress
            status 200
          rescue StandardError => e
            Rails.logger.error { "Error: #{e} while generating payment address for #{params[:currency]} for user: #{params[:uid]}" }
            error!({ errors: ['management.payment_address.failed_to_generate'] }, 422)
          end
        end
      end
    end
  end
end
