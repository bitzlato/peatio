class AccountMetrics < Influxer::Metrics
  tags :account_id
  attributes :balance, :locked, :amount

  scope :balance_changes, ->(group_by = '1d', fill = 'previous') do
    select('LAST(balance) as balance, LAST(locked) as locked, LAST(amount) as amount')
      .time(group_by).fill(fill)
  end
end
