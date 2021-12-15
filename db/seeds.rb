# frozen_string_literal: true

# NOTE: The order of task matters because Currency belongs_to Blockchain.
Rake::Task['seed:accounts'].invoke
Rake::Task['seed:blockchains'].invoke
Rake::Task['seed:currencies'].invoke
Rake::Task['seed:engines'].invoke
Rake::Task['seed:markets'].invoke
Rake::Task['seed:wallets'].invoke
Rake::Task['seed:trading_fees'].invoke

Member.create!(level: 3, role: 'member', uid: 'U123456789', state: :active)
