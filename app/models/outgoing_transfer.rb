class OutgoingTransfer < Transaction
  belongs_to :user
  belongs_to :money_account

  validates :user, :money_account, presence: true
  validates :amount_cents, numericality: { less_than: 0 }

  def outgoing_transfer?
    true
  end

  def transferer_money_account
    IncomingTransfer.where(
      user:,
      amount_cents: amount_cents * -1,
      description:,
      account_id:
    ).where(created_at: (created_at - 1.second)..(created_at + 1.second))
     .first&.money_account
  end

  private

  def set_account_id
    self.account_id = user.account_id
  end
end
