# frozen_string_literal: true

class BelomorRecord < ApplicationRecord
  self.abstract_class = true
  establish_connection :"belomor_#{Rails.env}"
end
