class OutgoingTransfer < Transaction
  belongs_to :user
  belongs_to :money_account

  validates :user, :money_account, presence: true
  validates :amount_cents, numericality: { less_than: 0 }

  def outgoing_transfer?
    true
  end

  private

  def set_account_id
    self.account_id = user.account_id
  end
end
