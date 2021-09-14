# frozen_string_literal: true

ActiveRecord::Base.logger = nil if ENV['DISABLE_ACTIVE_RECORD_LOGGING']
