require 'digest'

module Dummy
  class Wallet < Peatio::Wallet::Abstract
    def initialize(features = {})
    end

    def configure(_settings = {})
      # do nothing
    end

    def load_balance!(_currency)
      # do nothing
    end
  end
end
