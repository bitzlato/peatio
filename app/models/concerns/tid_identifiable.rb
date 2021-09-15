# frozen_string_literal: true

module TIDIdentifiable
  extend ActiveSupport::Concern

  included do
    validates :tid, presence: true, uniqueness: { case_sensitive: false }

    before_validation do
      next if tid.present?

      loop do
        self.tid = "TID#{SecureRandom.hex(5).upcase}"
        break unless self.class.where(tid: tid).any?
      end
    end
  end
end
