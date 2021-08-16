# frozen_string_literal: true

namespace :db do
  desc 'Nullify Peatio encrypted columns'
  task nullify_encrypted_columns: %i[check_protected_environments environment] do
    raise "Can't be executed in production" if Rails.env.production?

    (ActiveRecord::Base.connection.tables - %w[ar_internal_metadata schema_migrations]).each do |table|
      model = table.classify.constantize rescue next
      model.column_names.each do |column_name|
        if column_name.end_with?('_encrypted')
          model.update_all("#{column_name}": nil)
          puts "#{table}.#{column_name} is nullified."
        end
      end
    end
    puts 'Done.'
  end
end
