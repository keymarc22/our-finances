class IncomingTransfer < Transaction
  belongs_to :user
  belongs_to :money_account

  validates :user, :money_account, presence: true
  validates :amount_cents, numericality: { greater_than: 0 }

  def incoming_transfer?
    true
  end

  private

  def set_account_id
    self.account_id = user.account_id
  end
end
