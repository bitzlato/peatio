# Rerurns deposit spreads
#
class DepositSpreader
  Error = Class.new StandardError

  def self.call(deposit)
    spread = new(deposit).call
    Rails.logger.warn { "The deposit #{deposit.id} was spread in the next way: #{spread}"}
    spread
  end

  def initialize(deposit)
    @deposit = deposit
  end

  def call
    spread_deposit @deposit
  end

  private

  def spread_deposit(deposit)
    destination_wallets =
      Wallet.active.withdraw.ordered
        .joins(:currencies).where(currencies: { id: deposit.currency_id })
        .map do |w|
        # NOTE: Consider min_collection_amount is defined per wallet.
        #       For now min_collection_amount is currency config.
        { address:                 w.address,
          balance:                 w.current_balance(deposit.currency),
          # Wallet max_balance will be in the platform currency
          max_balance:             (w.max_balance / deposit.currency.get_price.to_d).round(deposit.currency.precision, BigDecimal::ROUND_DOWN),
          min_collection_amount:   deposit.currency.min_collection_amount,
          skip_deposit_collection: w.service.skip_deposit_collection?,
          plain_settings:          w.plain_settings }
      end
    raise StandardError, "destination wallets don't exist" if destination_wallets.blank?

    # Since last wallet is considered to be the most secure we need always
    # have it in spread even if we don't know the balance.
    # All money which doesn't fit to other wallets will be collected to cold.
    # That is why cold wallet balance is considered to be 0 because there is no
    destination_wallets.last[:balance] = 0

    # Remove all wallets not available current balance
    # (except the last one see previous comment).
    destination_wallets.reject! { |dw| dw[:balance] == Wallet::NOT_AVAILABLE }

    spread_between_wallets(deposit, destination_wallets)
  end

  # @return [Array<Peatio::Transaction>] result of spread in form of
  # transactions array with amount and to_address defined.
  def spread_between_wallets(deposit, destination_wallets)
    original_amount = deposit.amount
    if original_amount < destination_wallets.pluck(:min_collection_amount).min
      return []
    end

    left_amount = original_amount

    spread = destination_wallets.map do |dw|
      amount_for_wallet = [dw[:max_balance] - dw[:balance], left_amount].min

      # If free amount in current wallet is too small,
      # we will not able to collect it.
      # Put 0 for this wallet.
      if amount_for_wallet < [dw[:min_collection_amount], 0].max
        amount_for_wallet = 0
      end

      left_amount -= amount_for_wallet

      # If amount left is too small we will not able to collect it.
      # So we collect everything to current wallet.
      if left_amount < dw[:min_collection_amount]
        amount_for_wallet += left_amount
        left_amount = 0
      end

      transaction_params = { to_address:  dw[:address],
                             amount: amount_for_wallet.to_d,
                             currency_id: deposit.currency_id,
                             options:     dw[:plain_settings]
                           }.compact

      transaction = Peatio::Transaction.new(transaction_params)

      # Tx will not be collected to this destination wallet
      transaction.status = :skipped if dw[:skip_deposit_collection]
      transaction
    rescue => e
      # If have exception skip wallet.
      report_exception(e)
    end

    if left_amount > 0
      # If deposit doesn't fit to any wallet, collect it to the last one.
      # Since the last wallet is considered to be the most secure.
      spread.last.amount += left_amount
      left_amount = 0
    end

    # Remove zero and skipped transactions from spread.
    spread.filter { |t| t.amount > 0 }.tap do |sp|
      unless sp.map(&:amount).sum == original_amount
        raise Error, "Deposit spread failed deposit.amount != collection_spread.values.sum"
      end
    end
  end
end
