# frozen_string_literal: true

%w[deposit withdraw trading].each do |ability|
  var = "MINIMUM_MEMBER_LEVEL_FOR_#{ability.upcase}"
  n   = ENV[var]

  raise ArgumentError, "The variable #{var} is not set." if n.blank?

  begin
    Integer(n)
  rescue ArgumentError
    raise ArgumentError, "The value of #{var} (#{n.inspect}) is not a valid number."
  end

  raise ArgumentError, "The value of #{var} (#{n.inspect}) must be in range of [0, 99]." if n.to_i < 0 || n.to_i > 99
end
