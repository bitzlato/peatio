module NumericHelpers
  def abi_encode(method, *args)
    '0x' + args.each_with_object(Digest::SHA3.hexdigest(method, 256)[0...8]) do |arg, data|
      data.concat(arg.gsub(/\A0x/, '').rjust(64, '0'))
    end
  end
end
