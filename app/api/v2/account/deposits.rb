# frozen_string_literal: true

require_relative '../validations'

module API
  module V2
    module Account
      class Deposits < Grape::API
        before { deposits_must_be_permitted! }

        desc 'Get your deposits history.',
             is_array: true,
             success: API::V2::Entities::Deposit

        params do
          optional :currency,
                   type: String,
                   values: { value: -> { Currency.visible.codes(bothcase: true) }, message: 'account.currency.doesnt_exist' },
                   desc: 'Currency code'
          optional :state,
                   values: { value: ->(v) { (Array.wrap(v) - ::Deposit.aasm.states.map(&:name).map(&:to_s)).blank? }, message: 'account.deposit.invalid_state' },
                   desc: 'Filter deposits by states.'
          optional :txid,
                   type: String,
                   allow_blank: false,
                   desc: 'Deposit transaction id.'
          optional :time_from,
                   allow_blank: { value: false, message: 'account.deposit.empty_time_from' },
                   type: { value: Integer, message: 'account.deposit.non_integer_time_from' },
                   desc: 'An integer represents the seconds elapsed since Unix epoch.'
          optional :time_to,
                   type: { value: Integer, message: 'account.deposit.non_integer_time_to' },
                   allow_blank: { value: false, message: 'account.deposit.empty_time_to' },
                   desc: 'An integer represents the seconds elapsed since Unix epoch.'
          optional :limit,
                   type: { value: Integer, message: 'account.deposit.non_integer_limit' },
                   values: { value: 1..100, message: 'account.deposit.invalid_limit' },
                   default: 100,
                   desc: 'Number of deposits per page (defaults to 100, maximum is 100).'
          optional :page,
                   type: { value: Integer, message: 'account.deposit.non_integer_page' },
                   values: { value: ->(p) { p.try(:positive?) }, message: 'account.deposit.non_positive_page' },
                   default: 1,
                   desc: 'Page number (defaults to 1).'
        end
        get '/deposits' do
          user_authorize! :read, ::Deposit

          currency = Currency.find(params[:currency]) if params[:currency].present?

          current_user.deposits.order(id: :desc)
                      .tap { |q| q.where!(currency: currency) if currency }
                      .tap { |q| q.where!(txid: params[:txid]) if params[:txid] }
                      .tap { |q| q.where!(aasm_state: params[:state]) if params[:state] }
                      .tap { |q| q.where!('updated_at >= ?', Time.at(params[:time_from])) if params[:time_from].present? }
                      .tap { |q| q.where!('updated_at <= ?', Time.at(params[:time_to])) if params[:time_to].present? }
                      .tap { |q| present paginate(q), with: API::V2::Entities::Deposit }
        end

        desc 'Get your deposits history with total.'
        params do
          optional :currency,
                   type: String,
                   values: { value: -> { Currency.visible.codes(bothcase: true) }, message: 'account.currency.doesnt_exist' },
                   desc: 'Currency code'
          optional :state,
                   values: { value: ->(v) { (Array.wrap(v) - ::Deposit.aasm.states.map(&:name).map(&:to_s)).blank? }, message: 'account.deposit.invalid_state' },
                   desc: 'Filter deposits by states.'
          optional :txid,
                   type: String,
                   allow_blank: false,
                   desc: 'Deposit transaction id.'
          optional :time_from,
                   allow_blank: { value: false, message: 'account.deposit.empty_time_from' },
                   type: { value: Integer, message: 'account.deposit.non_integer_time_from' },
                   desc: 'An integer represents the seconds elapsed since Unix epoch.'
          optional :time_to,
                   type: { value: Integer, message: 'account.deposit.non_integer_time_to' },
                   allow_blank: { value: false, message: 'account.deposit.empty_time_to' },
                   desc: 'An integer represents the seconds elapsed since Unix epoch.'
          optional :limit,
                   type: { value: Integer, message: 'account.deposit.non_integer_limit' },
                   values: { value: 1..100, message: 'account.deposit.invalid_limit' },
                   default: 100,
                   desc: 'Number of deposits per page (defaults to 100, maximum is 100).'
          optional :page,
                   type: { value: Integer, message: 'account.deposit.non_integer_page' },
                   values: { value: ->(p) { p.try(:positive?) }, message: 'account.deposit.non_positive_page' },
                   default: 1,
                   desc: 'Page number (defaults to 1).'
        end
        get '/deposits_t' do
          user_authorize! :read, ::Deposit

          currency = Currency.find(params[:currency]) if params[:currency].present?

          deposits = current_user.deposits.order(id: :desc)
                                 .tap { |q| q.where!(currency: currency) if currency }
                                 .tap { |q| q.where!(txid: params[:txid]) if params[:txid] }
                                 .tap { |q| q.where!(aasm_state: params[:state]) if params[:state] }
                                 .tap { |q| q.where!('updated_at >= ?', Time.at(params[:time_from])) if params[:time_from].present? }
                                 .tap { |q| q.where!('updated_at <= ?', Time.at(params[:time_to])) if params[:time_to].present? }
          total = deposits.count

          present :data, paginate(deposits), with: API::V2::Entities::Deposit
          present :total, total
        end

        desc 'Get details of specific deposit.' do
          success API::V2::Entities::Deposit
        end
        params do
          requires :txid,
                   type: String,
                   allow_blank: false,
                   desc: 'Deposit transaction id'
        end
        get '/deposits/:txid' do
          user_authorize! :read, ::Deposit

          deposit = current_user.deposits.find_by!(txid: params[:txid])
          present deposit, with: API::V2::Entities::Deposit
        end

        desc 'Returns deposit address. ' \
             'The address may be blank because address generation process is still in progress. ' \
             'If this case you should try again later.',
             success: API::V2::Entities::PaymentAddress
        params do
          requires :blockchain,
                   type: String,
                   values: { value: -> { ::Blockchain.active.pluck(:id).map(&:to_s) + ::Blockchain.active.pluck(:key) }, message: 'account.blockchain.doesnt_exist' },
                   desc: 'Blockchain ID or key.'
        end
        get '/deposit_address/:blockchain' do
          user_authorize! :read, ::PaymentAddress

          blockchain = Blockchain.find_by(id: params[:blockchain]) || Blockchain.find_by(key: params[:blockchain])
          error!({ errors: ['account.blockchain.no_deposit_address_invoices_only'] }, 422) if blockchain.enable_invoice?

          payment_address = current_user.payment_address(blockchain)
          present payment_address, with: API::V2::Entities::PaymentAddress
        end
      end
    end
  end
end
