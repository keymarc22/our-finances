account = Account.create(name: 'Testing account')

users = [
  { email: 'test@email1.com', name: 'Test User 1' },
  { email: 'test2@email1.com', name: 'Test User 2' }
].map do |attrs|
  user = User.find_or_create_by!(email: attrs[:email]) do |user|
    user.name = attrs[:name]
    user.password = 'password123'
    user.password_confirmation = 'password123'
    user.account = account
  end

  money_account = MoneyAccount.create!(name: "Account #{user.id}", user: user, account:)
  Incoming.create(amount_cents: 100000, money_account:, description: 'Initial deposit', transaction_date: Date.today, account:)
  user
end

expenses = [
  { description: 'Groceries', amount: 100.0, user: users[0] },
  { description: 'Utilities', amount: 60.0, user: users[1] }
].map do |attrs|
  Expense.create!(
    description: attrs[:description],
    amount: attrs[:amount],
    user: attrs[:user],
    money_account_id: MoneyAccount.first.id,
    transaction_type: :personal,
    transaction_date: Date.today,
    account: account
  )
end

expenses_splits = [
  { expense: expenses[0], user: users[0], amount: 50.0 },
  { expense: expenses[0], user: users[1], amount: 50.0 },
  { expense: expenses[1], user: users[0], amount: 30.0 },
  { expense: expenses[1], user: users[1], amount: 30.0 }
]

expenses_splits.each do |attrs|
  ExpenseSplit.create!(
    expense: attrs[:expense],
    user: attrs[:user],
    amount_cents: attrs[:amount],
    percentage: 50
  )
end
