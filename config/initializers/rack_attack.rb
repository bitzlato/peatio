# frozen_string_literal: true

module Rack
  class Attack
    throttle('limit beneficiary activations by uid', limit: 1, period: 30) do |req|
      req.env.dig('jwt.payload', 'uid') if req.path =~ %r{/api/v2/account/beneficiaries/\d+/activate} && req.patch?
    end

    throttle('limit withdraw creations by uid', limit: 1, period: 5) do |req|
      req.env.dig('jwt.payload', 'uid') if req.path == '/api/v2/account/withdraws' && req.post?
    end

    throttle('limit internal transfers by uid', limit: 1, period: 5) do |req|
      req.env.dig('jwt.payload', 'uid') if req.path == '/api/v2/account/internal_transfers' && req.post?
    end
  end
end
