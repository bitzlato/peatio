# frozen_string_literal: true

module API
  module V2
    module Admin
      class Blockchains < Grape::API
        helpers ::API::V2::Admin::Helpers

        namespace :blockchains do
          desc 'Get all blockchains, result is paginated.',
               is_array: true,
               success: API::V2::Admin::Entities::Blockchain
          params do
            optional :key,
                     values: { value: -> { ::Blockchain.pluck(:key) }, message: 'admin.blockchain.blockchain_key_doesnt_exist' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:key][:desc] }
            optional :client,
                     values: { value: -> { ::Blockchain.clients.map(&:to_s) }, message: 'admin.blockchain.blockchain_client_doesnt_exist' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:client][:desc] }
            optional :status,
                     values: { value: -> { %w[active disabled] }, message: 'admin.blockchain.blockchain_status_doesnt_exist' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:status][:desc] }
            optional :name,
                     values: { value: -> { ::Blockchain.pluck(:name) }, message: 'admin.blockchain.blockchain_name_doesnt_exist' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:name][:desc] }
            use :pagination
            use :ordering
          end
          get do
            admin_authorize! :read, ::Blockchain

            ransack_params = Helpers::RansackBuilder.new(params)
                                                    .eq(:key, :client, :status, :name)
                                                    .build

            search = ::Blockchain.ransack(ransack_params)
            search.sorts = "#{params[:order_by]} #{params[:ordering]}"
            present paginate(search.result), with: API::V2::Admin::Entities::Blockchain
          end

          desc 'Get available blockchain clients.',
               is_array: true
          get '/clients' do
            Blockchain.clients
          end

          desc 'Get a blockchain.' do
            success API::V2::Admin::Entities::Blockchain
          end
          params do
            requires :id,
                     type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:id][:desc] }
          end
          get '/:id' do
            admin_authorize! :read, ::Blockchain

            present Blockchain.find(params[:id]), with: API::V2::Admin::Entities::Blockchain
          end

          desc 'Get a latest blockchain block.'
          params do
            requires :id,
                     type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
                     desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:id][:desc] }
          end
          get '/:id/latest_block' do
            admin_authorize! :read, ::Blockchain

            Blockchain.find(params[:id])&.gateway.latest_block_number
          rescue StandardError
            error!({ errors: ['admin.blockchain.latest_block'] }, 422)
          end

          # desc 'Create new blockchain.' do
          # success API::V2::Admin::Entities::Blockchain
          # end
          # params do
          # requires :key,
          # values: { value: -> (v){ v && v.length < 255 }, message: 'admin.blockchain.key_too_long' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:key][:desc] }
          # requires :name,
          # values: { value: -> (v){ v && v.length < 255 }, message: 'admin.blockchain.name_too_long' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:name][:desc] }
          # requires :client,
          # values: { value: -> { ::Blockchain.clients.map(&:to_s) }, message: 'admin.blockchain.invalid_client' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:client][:desc] }
          # requires :height,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_height' },
          # values: { value: -> (p){ p.try(:positive?) }, message: 'admin.blockchain.non_positive_height' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:height][:desc] }
          # optional :explorer_transaction,
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:explorer_transaction][:desc] }
          # optional :explorer_address,
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:explorer_address][:desc] }
          # optional :server,
          # regexp: { value: URI::regexp, message: 'admin.blockchain.invalid_server' },
          # desc: -> { 'Blockchain server url' }
          # optional :status,
          # values: { value: %w(active disabled), message: 'admin.blockchain.invalid_status' },
          # default: 'active',
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:status][:desc] }
          # optional :min_confirmations,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_min_confirmations' },
          # values: { value: -> (p){ p.try(:positive?) }, message: 'admin.blockchain.non_positive_min_confirmations' },
          # default: 6,
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:min_confirmations][:desc] }
          # end
          # post '/new' do
          # admin_authorize! :create, ::Blockchain

          # blockchain = Blockchain.new(declared(params))
          # if blockchain.save
          # present blockchain, with: API::V2::Admin::Entities::Blockchain
          # status 201
          # else
          # body errors: blockchain.errors.full_messages
          # status 422
          # end
          # end

          # desc 'Update blockchain.' do
          # success API::V2::Admin::Entities::Blockchain
          # end
          # params do
          # requires :id,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:id][:desc] }
          # optional :key,
          # type: String,
          # values: { value: -> (v){ v.length < 255 }, message: 'admin.blockchain.key_too_long' },
          # coerce_with: ->(v) { v.strip.downcase },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:key][:desc] }
          # optional :name,
          # values: { value: -> (v){ v.length < 255 }, message: 'admin.blockchain.name_too_long' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:name][:desc] }
          # optional :client,
          # values: { value: -> { ::Blockchain.clients.map(&:to_s) }, message: 'admin.blockchain.invalid_client' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:client][:desc] }
          # optional :server,
          # regexp: { value: URI::regexp, message: 'admin.blockchain.invalid_server' },
          # desc: -> { 'Blockchain server url' }
          # optional :height,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_height' },
          # values: { value: -> (p){ p.try(:positive?) }, message: 'admin.blockchain.non_positive_height' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:height][:desc] }
          # optional :explorer_transaction,
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:explorer_transaction][:desc] }
          # optional :explorer_address,
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:explorer_address][:desc] }
          # optional :status,
          # values: { value: %w(active disabled), message: 'admin.blockchain.invalid_status' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:status][:desc] }
          # optional :min_confirmations,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_min_confirmations' },
          # values: { value: -> (p){ p.try(:positive?) }, message: 'admin.blockchain.non_positive_min_confirmations' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:min_confirmations][:desc] }
          # end
          # post '/update' do
          # admin_authorize! :update, ::Blockchain, params.except(:id)

          # blockchain = Blockchain.find(params[:id])
          # if blockchain.update(declared(params, include_missing: false))
          # present blockchain, with: API::V2::Admin::Entities::Blockchain
          # else
          # body errors: blockchain.errors.full_messages
          # status 422
          # end
          # end

          # desc 'Process blockchain\'s block.' do
          # success API::V2::Admin::Entities::Blockchain
          # end
          # params do
          # requires :id,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
          # desc: -> { API::V2::Admin::Entities::Blockchain.documentation[:id][:desc] }
          # requires :block_number,
          # type: { value: Integer, message: 'admin.blockchain.non_integer_block_number' },
          # values: { value: -> (p){ p.try(:positive?) }, message: 'admin.blockchain.non_positive_block_number' },
          # desc: -> { 'The id of a particular block on blockchain' }
          # end
          # post '/process_block' do
          # admin_authorize! :update, ::Blockchain

          # blockchain = Blockchain.find(params[:id])
          # begin
          # blockchain.blockchain_api.process_block(params[:block_number])
          # present blockchain, with: API::V2::Admin::Entities::Blockchain
          # status 201
          # rescue StandardError => e
          # Rails.logger.error { "Error: #{e} while processing block #{params[:block_number]} of blockchain id: #{params[:id]}" }
          # error!({ errors: ['admin.blockchain.process_block'] }, 422)
          # end
          # end
        end
      end
    end
  end
end
