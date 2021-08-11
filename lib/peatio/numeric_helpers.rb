module NumericHelpers
  def abi_encode(method, *args)
    '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
      data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
    end
  end

  def convert_from_base_unit(value, base_factor)
    value.to_d / base_factor
  end

  def convert_to_base_unit(value, base_factor)
    x = value.to_d * base_factor
    unless (x % 1).zero?
      raise "Failed to convert value to base (smallest) unit because it exceeds the maximum precision: " \
        "#{value.to_d} - #{x.to_d} must be equal to zero."
    end
    x.to_i
  end
end
