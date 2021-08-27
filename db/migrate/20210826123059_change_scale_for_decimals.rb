# frozen_string_literal: true

class ChangeScaleForDecimals < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      (connection.tables - %w[ar_internal_metadata schema_migrations]).each do |table|
        connection.columns(table).each do |column|
          next unless column.scale == 16

          precision = column.precision == 32 ? 36 : column.precision - column.scale + 18
          options = { precision: precision, scale: 18, null: column.null }
          options[:default] = column.default.to_i if column.default.present?
          change_column table, column.name, :decimal, options
        end
      end
    end
  end
end
