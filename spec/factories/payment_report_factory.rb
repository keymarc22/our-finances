FactoryBot.define do
  factory :payment_report do
    association :account
    year { Date.current.year }
    month { Date.current.month }
    rate_a { 55.5 }
    rate_b { 45.0 }
  end
end
