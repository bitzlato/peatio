# frozen_string_literal: true

module API
  module P2P
    class Mount < Grape::API
      API_VERSION = 'v1'

      format         :json
      content_type   :json, 'application/json'
      default_format :json

      do_not_route_options!

      logger Rails.logger.dup
      logger.formatter = if Rails.env.production?
                           GrapeLogging::Formatters::Json.new
                         else
                           GrapeLogging::Formatters::Rails.new
                         end
      use GrapeLogging::Middleware::RequestLogger,
          logger: logger,
          log_level: :info,
          include: [GrapeLogging::Loggers::Response.new,
                    GrapeLogging::Loggers::FilterParameters.new,
                    GrapeLogging::Loggers::ClientEnv.new,
                    GrapeLogging::Loggers::RequestHeaders.new]

      mount Profile::Mount       => :profile
      # mount Public::Mount        => :public

      # The documentation is accessible at http://localhost:3000/swagger?url=/api/v2/swagger
      # Add swagger documentation for Peatio User API
      add_swagger_documentation base_path: File.join(API::Mount::PREFIX, API_VERSION, 'p2p'),
                                add_base_path: true,
                                mount_path: '/swagger',
                                api_version: API_VERSION,
                                doc_version: Peatio::Application::VERSION,
                                info: {
                                  title: "Bitzlato P2P API #{API_VERSION}",
                                  description: 'API for P2P application.',
                                  contact_name: Peatio::App.config.official_name,
                                  contact_email: Peatio::App.config.official_email,
                                  contact_url: Peatio::App.config.official_website,
                                  license: 'MIT',
                                  license_url: 'https://github.com/bitzlato/peatio/blob/master/LICENSE.md'
                                },
                                # models: [ ],
                                security_definitions: {
                                  Bearer: {
                                    type: 'apiKey',
                                    name: 'JWT',
                                    in: 'header'
                                  }
                                }
    end
  end
end
