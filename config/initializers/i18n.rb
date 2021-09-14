# frozen_string_literal: true

Rails.application.config.i18n.available_locales = ENV.fetch('AVAILABLE_LOCALES', 'en ru').split
