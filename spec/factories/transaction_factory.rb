FactoryBot.define do
  factory :transaction do
    description  { Faker::Lorem.sentence }
    amount_cents { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    transaction_date { Faker::Date.backward(days: 30) }
    transaction_type { :personal }
    association :user
    association :money_account
    account

    factory :expense, class: 'Expense' do
      amount_cents { -Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    end

    factory :incoming, class: 'Incoming' do
    end
  end

  factory :expense_split do
    association :expense
    association :user
    percentage { Faker::Number.between(from: 1, to: 100) }
  end
end
