module ServiceBase
  def failure(errors:)
    ServiceBase::Result.new(errors: errors)
  end

  def success(data: nil)
    ServiceBase::Result.new(data: data)
  end
end
