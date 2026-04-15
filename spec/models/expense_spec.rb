require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:account) { create(:account, name: "Cuenta test") }
  let(:user) { create(:user, email: "test@example.com", account: account) }
  let(:money_account) do
    ma = create(:money_account, name: "Efectivo", account: account, user: user)
    ma.incomings.create!(amount_cents: 100_000, description: 'Ingreso', user: user, transaction_date: Date.today)
    ma
  end
  let(:budget) { create(:budget, name: "Presupuesto", amount: 1000, account: account, user: user) }

  let(:valid_attributes) do
    {
      user:, money_account:, account:,
      transaction_date: Date.today,
      amount_cents: -1000,
      description: 'Test expense'
    }
  end

  describe 'validations' do
    it "is valid with valid attributes" do
      expense = Expense.new(valid_attributes)
      expect(expense).to be_valid
    end

    it "is invalid without amount_cents" do
      expense = Expense.new(valid_attributes.merge(amount_cents: nil))
      allow_any_instance_of(MoneyAccount).to receive(:balance_for).and_return(true)
      expect(expense).not_to be_valid
      expect(expense.errors[:amount_cents]).to be_present
    end

    it "is invalid with positive amount_cents" do
      expense = Expense.new(valid_attributes.merge(amount_cents: 1000))
      expect(expense).not_to be_valid
      expect(expense.errors[:amount_cents]).to be_present
    end

    it "is invalid with zero amount_cents" do
      expense = Expense.new(valid_attributes.merge(amount_cents: 0))
      expect(expense).not_to be_valid
    end

    it "is invalid without user_id if no budget_id" do
      expense = Expense.new(valid_attributes.except(:user).merge(budget: nil))
      expect(expense).not_to be_valid
      expect(expense.errors[:user_id]).to be_present
    end

    it "is valid without user_id if budget_id is present" do
      expense = Expense.new(valid_attributes.except(:user).merge(budget: budget))
      expect(expense).to be_valid
    end

    it "is valid without user_id if cutoff type" do
      expense = Expense.new(valid_attributes.except(:user).merge(transaction_type: :cutoff))
      expect(expense).to be_valid
    end

    it "is invalid without money_account_id if no budget_id" do
      expense = Expense.new(valid_attributes.except(:money_account).merge(budget: nil))
      expect(expense).not_to be_valid
      expect(expense.errors[:money_account_id]).to be_present
    end

    it "is invalid without transaction_date if no budget_id" do
      expense = Expense.new(valid_attributes.merge(transaction_date: nil, budget: nil))
      expect(expense).not_to be_valid
      expect(expense.errors[:transaction_date]).to be_present
    end

    it "is invalid when amount exceeds money account balance" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -999_999))
      expect(expense).not_to be_valid
      expect(expense.errors[:base]).to include("Insufficient funds in the money account.")
    end

    it "is valid when amount leaves money account at exactly zero" do
      balance = money_account.balance.cents
      expense = Expense.new(valid_attributes.merge(amount_cents: -balance))
      expect(expense).to be_valid
    end
  end

  describe '#amount=' do
    it "converts positive values to negative" do
      expense = Expense.new(valid_attributes)
      expense.amount = 500
      expect(expense.amount_cents).to eq(-50000)
    end

    it "keeps negative values as negative" do
      expense = Expense.new(valid_attributes)
      expense.amount = -500
      expect(expense.amount_cents).to eq(-50000)
    end

    it "converts positive string values to negative" do
      expense = Expense.new(valid_attributes)
      expense.amount = "500"
      expect(expense.amount_cents).to eq(-50000)
    end
  end

  describe '#expense?' do
    it "returns true" do
      expect(Expense.new.expense?).to be true
    end
  end

  describe '#amount_formatted' do
    it "returns formatted amount" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -5000))
      expect(expense.amount_formatted).to eq('$-50.00')
    end
  end

  describe '#parent' do
    it "returns money_account when present" do
      expense = Expense.new(valid_attributes)
      expect(expense.parent).to eq(money_account)
    end

    it "returns budget when no money_account" do
      expense = Expense.new(valid_attributes.except(:money_account).merge(budget: budget))
      expect(expense.parent).to eq(budget)
    end
  end

  describe '#total_splits_percentage' do
    it "calculates total splits percentage" do
      expense = Expense.create!(valid_attributes)
      expense.expense_splits.create!(user: user, percentage: 100)
      expect(expense.total_splits_percentage).to eq(100)
    end
  end

  describe '#amount_for_user' do
    it "returns the split amount for a user" do
      expense = Expense.create!(valid_attributes.merge(amount_cents: -10000))
      expense.expense_splits.create!(user: user, percentage: 60)
      expect(expense.amount_for_user(user)).to eq(Money.new(-6000))
    end

    it "returns 0 if the user has no split" do
      expense = Expense.create!(valid_attributes)
      other_user = create(:user, account: account)
      expect(expense.amount_for_user(other_user)).to eq(0)
    end
  end

  describe '#split_details' do
    it "returns an array of split details" do
      expense = Expense.create!(valid_attributes.merge(amount_cents: -10000))
      expense.expense_splits.create!(user: user, percentage: 100)

      details = expense.split_details
      expect(details.length).to eq(1)
      expect(details.first[:user]).to eq(user)
      expect(details.first[:percentage]).to eq(100)
      expect(details.first[:amount]).to eq(Money.new(-10000))
    end
  end

  describe 'splits validation' do
    it "validates splits sum to 100 percent for shared" do
      expense = Expense.create!(valid_attributes.merge(transaction_type: :shared))
      expense.expense_splits.create!(user: user, percentage: 50)
      expect(expense.total_splits_percentage).to eq(50)
      expect(expense.total_splits_percentage).not_to eq(100)
    end
  end

  describe 'currency conversion' do
    it "converts amount when exchange_currency differs from amount_currency" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -9000, exchange_currency: 'VES', exchange_rate: 450))
      expense.valid?
      expect(expense.amount_cents).to eq(-20)
    end

    it "does not convert when exchange_currency matches amount_currency" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -9000, exchange_currency: 'VES', exchange_rate: 450, amount_currency: 'VES'))
      expense.valid?
      expect(expense.amount_cents).to eq(-9000)
      expect(expense.amount_currency).to eq('VES')
    end

    it "does not convert when exchange_currency is blank" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -5000, exchange_rate: 450))
      expense.valid?
      expect(expense.amount_cents).to eq(-5000)
    end

    it "does not convert when exchange_rate is blank" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -5000, exchange_currency: 'VES'))
      expense.valid?
      expect(expense.amount_cents).to eq(-5000)
    end

    it "rounds converted amount correctly" do
      expense = Expense.new(valid_attributes.merge(amount_cents: -10000, exchange_currency: 'VES', exchange_rate: 300))
      expense.valid?
      expect(expense.amount_cents).to eq(-33)
    end

    it "check_balance uses the converted amount, not the original" do
      # money_account has 100_000 cents ($1000). A VES amount of -9_000_000 would exceed
      # the balance without conversion, but converted at rate 100 it becomes -90_000 cents ($900)
      expense = Expense.new(valid_attributes.merge(amount_cents: -9_000_000, exchange_currency: 'VES', exchange_rate: 100))
      expect(expense).to be_valid
      expect(expense.amount_cents).to eq(-90_000)
    end

    it "is invalid when converted amount exceeds balance" do
      # money_account has 100_000 cents ($1000). VES -500_000 / rate 2 = -250_000 cents ($2500) > $1000
      expense = Expense.new(valid_attributes.merge(amount_cents: -500_000, exchange_currency: 'VES', exchange_rate: 2))
      expect(expense).not_to be_valid
      expect(expense.errors[:base]).to include("Insufficient funds in the money account.")
    end
  end

  describe '#check_balance' do
    context 'al crear' do
      it "es válido cuando el monto no supera el balance" do
        expense = Expense.new(valid_attributes.merge(amount_cents: -50_000))
        expect(expense).to be_valid
      end

      it "es inválido cuando el monto supera el balance" do
        expense = Expense.new(valid_attributes.merge(amount_cents: -999_999))
        expect(expense).not_to be_valid
        expect(expense.errors[:base]).to include("Insufficient funds in the money account.")
      end

      it "es válido cuando el monto deja el balance exactamente en cero" do
        balance = money_account.balance.cents
        expense = Expense.new(valid_attributes.merge(amount_cents: -balance))
        expect(expense).to be_valid
      end
    end

    context 'al editar' do
      let!(:expense) { Expense.create!(valid_attributes.merge(amount_cents: -1000)) }

      it "valida el balance cuando amount_cents cambia y el nuevo monto supera el balance" do
        expense.amount_cents = -999_999
        expect(expense).not_to be_valid
        expect(expense.errors[:base]).to include("Insufficient funds in the money account.")
      end

      it "es válido cuando amount_cents cambia y el monto cabe en el balance" do
        expense.amount_cents = -500
        expect(expense).to be_valid
      end

      it "omite la validación de balance cuando amount_cents no cambia" do
        # Vaciamos el balance para que cualquier chequeo real fallara
        allow(money_account).to receive(:balance_for).and_return(false)
        allow(expense).to receive(:money_account).and_return(money_account)

        expense.description = "Descripción actualizada"
        expect(expense).to be_valid
      end
    end
  end

  describe 'scopes' do
    it ".fixed returns only fixed expenses" do
      fixed = Expense.create!(valid_attributes.merge(fixed: true, description: 'Fixed'))
      Expense.create!(valid_attributes.merge(fixed: false, description: 'Not fixed'))

      expect(Expense.fixed).to eq([fixed])
    end
  end
end
