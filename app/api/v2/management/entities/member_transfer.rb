# frozen_string_literal: true

module API
  module V2
    module Management
      module Entities
        class MemberTransfer < Base
          expose :key,
                 documentation: {
                   type: String,
                   desc: 'Unique Transfer Key.'
                 }

          expose :member_id
          expose :member_uid
          expose :amount
          expose :service
          expose :meta
          expose :description,
                 documentation: {
                   type: String,
                   desc: 'Transfer Description'
                 }
        end
      end
    end
  end
end
