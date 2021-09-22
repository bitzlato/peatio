
module API::P2P
  module Profile
    class Mount < Grape::API
      before { authenticate! }
      before { set_ets_context! }

      mount Market::Orders
      mount Market::Trades
    end
  end
end
