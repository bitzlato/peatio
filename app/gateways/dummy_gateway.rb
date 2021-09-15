# frozen_string_literal: true

class DummyGateway < AbstractGateway
  private

  def build_client
    nil
  end
end
