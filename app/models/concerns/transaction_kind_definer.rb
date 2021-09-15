# frozen_string_literal: true

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

  def define_direction
    return :failed if failed?

    if from_wallet? || from_deposit?
      if to_wallet? || to_deposit?
        :internal
      else
        :outcome
      end
    elsif to_wallet? || to_deposit?
      :income
    else
      :unknown
    end
  end
end
