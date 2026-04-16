FactoryBot.define do
  factory :monthly_bill_payment do
    association :monthly_bill
    association :expense
    year { Date.today.year }
    month { Date.today.month }
    paid_at { Time.current }
  end
end
