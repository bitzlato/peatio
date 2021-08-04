class Settings < Settingslogic
  source "#{Rails.root}/config/settings.yml"
  source "#{Rails.root}/config/settings.local.yml"
  namespace Rails.env

  suppress_errors Rails.env.production?
end
