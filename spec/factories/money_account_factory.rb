FactoryBot.define do
  factory :money_account do
    name { Faker::Bank.name }
    association :user
    account

    trait :with_incoming do
      after(:create) do |money_account|
        create(:incoming, money_account:, user: money_account.user, account: money_account.account)
      end
    end
  end
end
