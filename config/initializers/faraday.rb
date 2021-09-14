# frozen_string_literal: true

class Faraday::Response
  def assert_success!
    raise "Response must be succcess #{status}" unless success?
  end
end
