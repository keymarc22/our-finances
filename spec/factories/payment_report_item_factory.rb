FactoryBot.define do
  factory :payment_report_item do
    association :payment_report
    name { Faker::Commerce.product_name }
    amount_cents { 10_000 }
    amount_currency { "USD" }
    save_as_monthly_bill { false }
    monthly_bill_id { nil }
  end
end
