module AccountTransactions
  AccountError = Class.new(StandardError)

  def plus_funds!(amount)
    update_columns(attributes_after_plus_funds!(amount))
  end

  def plus_funds(amount)
    with_lock { plus_funds!(amount) }
    self
  end

  def attributes_after_plus_funds!(amount)
    raise AccountError, "Cannot add funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance})." if amount <= ZERO

    { balance: balance + amount }
  end

  def plus_locked_funds!(amount)
    update_columns(attributes_after_plus_locked_funds!(amount))
  end

  def plus_locked_funds(amount)
    with_lock { plus_locked_funds!(amount) }
    self
  end

  def attributes_after_plus_locked_funds!(amount)
    raise AccountError, "Cannot add funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, locked: #{locked})." if amount <= ZERO

    { locked: locked + amount }
  end

  def sub_funds!(amount)
    update_columns(attributes_after_sub_funds!(amount))
  end

  def sub_funds(amount)
    with_lock { sub_funds!(amount) }
    self
  end

  def attributes_after_sub_funds!(amount)
    raise AccountError, "Cannot subtract funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance})." if amount <= ZERO || amount > balance

    { balance: balance - amount }
  end

  def lock_funds!(amount)
    update_columns(attributes_after_lock_funds!(amount))
  end

  def lock_funds(amount)
    with_lock { lock_funds!(amount) }
    self
  end

  def attributes_after_lock_funds!(amount)
    raise AccountError, "Cannot lock funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance}, locked: #{locked})." if amount <= ZERO || amount > balance

    { balance: balance - amount, locked: locked + amount }
  end

  def unlock_funds!(amount)
    update_columns(attributes_after_unlock_funds!(amount))
  end

  def unlock_funds(amount)
    with_lock { unlock_funds!(amount) }
    self
  end

  def attributes_after_unlock_funds!(amount)
    raise AccountError, "Cannot unlock funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, balance: #{balance} locked: #{locked})." if amount <= ZERO || amount > locked

    { balance: balance + amount, locked: locked - amount }
  end

  def unlock_and_sub_funds!(amount)
    update_columns(attributes_after_unlock_and_sub_funds!(amount))
  end

  def unlock_and_sub_funds(amount)
    with_lock { unlock_and_sub_funds!(amount) }
    self
  end

  def attributes_after_unlock_and_sub_funds!(amount)
    raise AccountError, "Cannot unlock and sub funds (member id: #{member_id}, currency id: #{currency_id}, amount: #{amount}, locked: #{locked})." if amount <= ZERO || amount > locked

    { locked: locked - amount }
  end

end
