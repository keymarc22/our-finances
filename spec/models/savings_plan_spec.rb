require 'rails_helper'

RSpec.describe SavingsPlan, type: :model do
  let(:user) { create(:user) }
  let(:money_account) { create(:money_account, :with_incoming, user:) }
  
  before do
    money_account.incomings.last.update(amount: 100_000) # Ensure the money account has sufficient funds for testing
  end
  
  describe 'associations' do
    it 'has many user_savings_plans and destroys them on delete' do
      savings_plan = create(:savings_plan, name: "Test", target_amount: 100, deadline: Date.tomorrow)
      user_savings_plan = savings_plan.user_savings_plans.create!(user: user)
      expect(savings_plan.user_savings_plans).to include(user_savings_plan)
      savings_plan.destroy
      expect(UserSavingsPlan.where(id: user_savings_plan.id)).to be_empty
    end

    it 'has many users through user_savings_plans' do
      savings_plan = create(:savings_plan, name: "Test", target_amount: 100, deadline: Date.tomorrow)
      savings_plan.user_savings_plans.create!(user: user)
      expect(savings_plan.users).to include(user)
    end

    it 'has many incomings and destroys them on delete' do
      savings_plan = create(:savings_plan, name: "Test", target_amount: 100, deadline: Date.tomorrow)
      incoming = savings_plan.incomings.create!(amount: 10, description: 'test incoming', transaction_date: Date.today, money_account:, user:)
      expect(savings_plan.incomings).to include(incoming)
      savings_plan.destroy
      expect(Incoming.where(id: incoming.id)).to be_empty
    end

    it 'has many expenses and destroys them on delete' do
      savings_plan = create(:savings_plan, name: "Test", target_amount: 100, deadline: Date.tomorrow)
      expense = savings_plan.expenses.create!(amount: 10, description: 'test expense', transaction_date: Date.today, money_account:, user:)
      expect(savings_plan.expenses).to include(expense)
      savings_plan.destroy
      expect(Expense.where(id: expense.id)).to be_empty
    end
  end

  describe 'validations' do
    it 'is invalid without a name' do
      plan = SavingsPlan.new(target_amount: 100, deadline: Date.tomorrow)
      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to be_present
    end

    it 'is invalid without a target_amount' do
      plan = SavingsPlan.new(name: "Test", deadline: Date.tomorrow)
      expect(plan).not_to be_valid
      expect(plan.errors[:target_amount]).to be_present
    end

    it 'is invalid if target_amount is not greater than 0' do
      plan = SavingsPlan.new(name: "Test", target_amount: 0, deadline: Date.tomorrow)
      expect(plan).not_to be_valid
      expect(plan.errors[:target_amount]).to be_present
    end

    it 'is invalid without a deadline' do
      plan = SavingsPlan.new(name: "Test", target_amount: 100)
      expect(plan).not_to be_valid
      expect(plan.errors[:deadline]).to be_present
    end
  end

  describe 'enums' do
    it 'defines plan_type enum with shared and personal' do
      expect(SavingsPlan.plan_types.keys).to match_array(%w[shared personal])
    end

    it 'defines status enum with active, completed, paused, cancelled' do
      expect(SavingsPlan.statuses.keys).to match_array(%w[active completed paused cancelled])
    end
  end

  describe 'methods' do
    let(:savings_plan) { create(:savings_plan, target_amount: 1000) }

    describe '#days_remaining' do
      it 'returns 0 if deadline is in the past' do
        savings_plan.deadline = Date.current - 1.day
        expect(savings_plan.days_remaining).to eq(0)
      end

      it 'returns the number of days remaining until the deadline' do
        savings_plan.deadline = Date.current + 10.days
        expect(savings_plan.days_remaining).to eq(10)
      end
    end

    describe '#monthly_target' do
      it 'returns 0 if days_remaining is zero or negative' do
        savings_plan.deadline = Date.current - 1.day
        expect(savings_plan.monthly_target.cents).to eq(0)
      end

      it 'returns the monthly target amount based on remaining amount and months left' do
        allow(savings_plan).to receive(:current_amount).and_return(Money.new(200))
        savings_plan.deadline = Date.current + 60.days # Roughly 2 months
        expect(savings_plan.monthly_target.cents).to eq(49900)
      end
    end
  end
end
