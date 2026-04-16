FactoryBot.define do
  factory :monthly_bill do
    name { Faker::Commerce.product_name }
    amount_cents { 50_000 }
    amount_currency { "USD" }
    active { true }
    association :account

    trait :with_due_day do
      due_day { 15 }
    end

    trait :inactive do
      active { false }
    end
  end
end
