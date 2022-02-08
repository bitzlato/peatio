# frozen_string_literal: true

module API
  module V2
    module Admin
      class Beneficiaries < Grape::API
        helpers ::API::V2::Admin::Helpers

        namespace :beneficiaries do
          desc 'Get list of beneficiaries',
               success: API::V2::Admin::Entities::Beneficiary
          params do
            use :uid
            use :ordering
            use :pagination
            optional :id,
                     type: Integer,
                     desc: -> { API::V2::Entities::Beneficiary.documentation[:id][:desc] }
            optional :currency,
                     values: { value: ->(v) { (Array.wrap(v) - ::Currency.codes).blank? }, message: 'account.currency.doesnt_exist' },
                     desc: 'Beneficiary currency code'
            optional :state,
                     type: Array[Integer],
                     values: { value: ->(v) { (Array.wrap(v) - ::Beneficiary::STATES_MAPPING.values).blank? }, message: 'account.beneficiary.invalid_state' },
                     desc: 'Beneficiary state',
                     coerce_with: lambda { |val|
                       val.map { |s| Beneficiary::STATES_MAPPING[s.to_sym] }
                     }
          end

          get do
            admin_authorize! :read, ::Beneficiary

            ransack_params = Helpers::RansackBuilder.new(params)
                                                    .eq(:id)
                                                    .in(:state)
                                                    .translate(uid: :member_uid)
                                                    .build

            beneficiaries = Beneficiary
            beneficiaries = beneficiaries.with_currency(params[:currency]) if params[:currency].present?
            search = beneficiaries.ransack(ransack_params)
            search.sorts = "#{params[:order_by]} #{params[:ordering]}"

            present paginate(search.result), with: API::V2::Admin::Entities::Beneficiary
          end

          desc 'Take an action on the beneficiary',
               success: API::V2::Admin::Entities::Beneficiary

          params do
            requires :id,
                     type: Integer,
                     desc: -> { API::V2::Admin::Entities::Beneficiary.documentation[:id][:desc] }
            requires :action,
                     type: String,
                     values: { value: -> { ::Beneficiary.aasm.events.map(&:name).map(&:to_s) }, message: 'admin.beneficiary.invalid_action' },
                     desc: "Valid actions are #{::Beneficiary.aasm.events.map(&:name)}."
          end

          post '/actions' do
            admin_authorize! :update, ::Beneficiary

            beneficiary = Beneficiary.find(params[:id])

            action = ::Beneficiary.aasm.events.map(&:name).map(&:to_s).find { |a| a == params[:action] }
            if action.present? && beneficiary.public_send("may_#{action}?")
              beneficiary.public_send("#{action}!")
              present beneficiary, with: API::V2::Admin::Entities::Beneficiary
            else
              body errors: ["admin.beneficiary.cannot_#{params[:action]}"]
              status 422
            end
          end
        end
      end
    end
  end
end
