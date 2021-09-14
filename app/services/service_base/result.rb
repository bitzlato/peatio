# frozen_string_literal: true

module ServiceBase
  class Result
    attr_reader :data, :errors

    def initialize(data: nil, errors: [])
      @data = data
      @errors = errors
    end

    def successful?
      @errors.empty?
    end

    def failed?
      !successful?
    end
  end
end
