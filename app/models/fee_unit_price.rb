# frozen_string_literal: true

class FeeUnitPrice < ApplicationRecord
  belongs_to :blockchain

  def self.price_range(duration = 1.hour)
    result = where('created_at > ?', duration.ago).select('MIN(price) AS min_price, MAX(price) AS max_price').take
    result[:min_price]..result[:max_price]
  end
end
