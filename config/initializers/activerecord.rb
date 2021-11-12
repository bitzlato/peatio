# frozen_string_literal: true

module ActiveRecord
  class Base
    def self.inherited(child)
      super
      validates_lengths_from_database unless child == ActiveRecord::SchemaMigration
    end
  end
end

Rails.configuration.database_support_json = \
  ActiveRecord::Base.configurations[Rails.env]['support_json']

Rails.configuration.database_adapter = \
  ActiveRecord::Base.configurations[Rails.env]['adapter']

ActiveRecord::Base.logger = nil if ENV['DISABLE_ACTIVE_RECORD_LOGGING']
