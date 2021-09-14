# frozen_string_literal: true

class Hash
  def fetch!(key)
    raise "Required key #{key.inspect} is missing or is blank!" if self[key].blank?

    self[key]
  end
end
