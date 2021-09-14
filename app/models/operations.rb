# frozen_string_literal: true

module Operations
  class << self
    def build_account_number(currency_id:, account_code:, member_uid: nil)
      [currency_id.to_s, account_code.to_s, member_uid].compact.join('-')
    end

    def split_account_number(account_number:)
      splitted_account_number = account_number.split('-')

      # Paying attention to currency names contained '-'
      if splitted_account_number[1].to_i.to_s == splitted_account_number[1]
        currency_id = splitted_account_number[0]
        code = splitted_account_number[1]
        member_uid = splitted_account_number[2]
      else
        currency_id = [splitted_account_number[0], splitted_account_number[1]].join('-')
        code = splitted_account_number[2]
        member_uid = splitted_account_number[3]
      end
      { currency_id: currency_id,
        code: code,
        member_uid: member_uid }
    end

    def klass_for(code:)
      account = Operations::Account.find_by(code: code) || raise("No Operations::Account found for code '#{code}'")
      { asset: Operations::Asset,
        liability: Operations::Liability,
        revenue: Operations::Revenue,
        expense: Operations::Expense }.fetch(account.type.to_sym)
    end

    def update_legacy_balance(liability)
      return unless liability.present? || liability.is_a?(Operations::Liability)

      account = liability.account
      legacy_account = liability.member.get_account(liability.currency)

      credit = liability.credit
      debit = liability.debit

      if account.kind.main?
        if liability.credit.nonzero?
          legacy_account.plus_funds(credit)
        else
          legacy_account.sub_funds(debit)
        end
      elsif account.kind.locked?
        if credit.nonzero?
          legacy_account.plus_funds(credit)
          legacy_account.lock_funds(credit)
        else
          legacy_account.unlock_and_sub_funds(debit)
        end
      end
    end

    def validate_accounting_equation(operations)
      balance_sheet = Hash.new(0)
      assets = operations.select { |op| op.is_a?(Operations::Asset) }
      liabilities = operations.select { |op| op.is_a?(Operations::Liability) }
      revenues = operations.select { |op| op.is_a?(Operations::Revenue) }
      expenses = operations.select { |op| op.is_a?(Operations::Expense) }

      (assets + expenses).each do |op|
        balance_sheet[op.currency_id] += op.amount
      end
      (liabilities + revenues).each do |op|
        balance_sheet[op.currency_id] -= op.amount
      end

      balance_sheet.delete_if { |_k, v| v.zero? }.empty?
    end
  end
end
