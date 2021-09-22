# frozen_string_literal: true

module API
  class Mount < Grape::API
    PREFIX = '/api'

    cascade false

    mount API::V2::Mount => API::V2::Mount::API_VERSION
    mount API::P2P::Mount => API::P2P::Mount::API_VERSION
  end
end
