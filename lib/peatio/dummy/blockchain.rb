module Dummy
  class Blockchain < Peatio::Blockchain::Abstract
    def initialize(custom_features = {})
      @features = custom_features
    end
  end
end
