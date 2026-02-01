FactoryBot.define do
  factory :transactions_report do
    association :account
    cutoff_date { 6.months.ago.to_date }
    status { :in_process }

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end

    trait :with_file do
      after(:create) do |report|
        report.file.attach(
          io: StringIO.new("test,data\n1,2"),
          filename: 'report.csv',
          content_type: 'text/csv'
        )
      end
    end
  end
end
