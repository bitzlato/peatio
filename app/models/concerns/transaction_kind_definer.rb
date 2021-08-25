module TransactionKindDefiner
  def define_kind
    if to_deposit?
      if from_wallet?
        :gas_refuel
      elsif from_deposit?
        :internal
      elsif from_unknown?
        :deposit
      else
        :unknown
      end
    elsif to_wallet?
      if from_deposit?
        :collection
      elsif from_wallet?
        :internal
      elsif from_unknown?
        :refill
      else
        :unknown
      end
    elsif to_unknown?
      if from_wallet?
        :withdraw
      elsif from_deposit?
        if failed?
          :unknown
        else
          :unauthorized_withdraw
        end
      else
        :unknown
      end
    else
      :unknown
    end
  end


end
