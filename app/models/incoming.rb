class Incoming < Transaction
  enum :transaction_type, { personal: 0, shared: 1, cutoff: 2 }, default: :personal

  belongs_to :money_account
  belongs_to :user, optional: true

  def incoming?
    true
  end

  private

  def set_account_id
    self.account_id = money_account.account_id
  end
end
