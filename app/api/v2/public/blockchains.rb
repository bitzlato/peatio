# frozen_string_literal: true

module API
  module V2
    module Public
      class Blockchains < Grape::API
        helpers ::API::V2::Admin::Helpers

        namespace :blockchains do
          desc 'Get all blockchains',
               is_array: true,
               success: API::V2::Entities::Blockchain
        end
        get do
          present Blockchain.order(:id), with: API::V2::Entities::Blockchain
        end

        desc 'Get a blockchain.' do
          success API::V2::Entities::Blockchain
        end
        params do
          requires :id,
                   type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
                   desc: -> { API::V2::Entities::Blockchain.documentation[:id][:desc] }
        end
        get '/:id' do
          present Blockchain.find(params[:id]), with: API::V2::Entities::Blockchain
        end

        desc 'Get a latest blockchain block.'
        params do
          requires :id,
                   type: { value: Integer, message: 'admin.blockchain.non_integer_id' },
                   desc: -> { API::V2::Entities::Blockchain.documentation[:id][:desc] }
        end
        get '/:id/latest_block' do
          Blockchain.find(params[:id]).gateway.latest_block_number
        rescue StandardError
          error!({ errors: ['admin.blockchain.latest_block'] }, 422)
        end
      end
    end
  end
end
