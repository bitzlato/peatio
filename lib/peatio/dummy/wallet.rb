require 'digest'

module Dummy
  class Wallet < Peatio::Wallet::Abstract
    def initialize(features = {})
      @features = features
    end
  end
end
