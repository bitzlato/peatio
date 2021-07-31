module API
  module V2
    module LocaleHelpers
      def available_locales
        @available_locales ||= I18n.available_locales.map(&:to_s)
      end

      def available_locale(locale)
        locale if available_locales.include? locale
      end

      def request_locale
        available_locale(params[:locale]) ||
          request.env.http_accept_language.preferred_language_from(I18n.available_locales)
      end
    end
  end
end
