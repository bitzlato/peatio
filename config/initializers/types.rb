# frozen_string_literal: true

ActiveRecord::Type.register(:uuid, UUID::Type)
