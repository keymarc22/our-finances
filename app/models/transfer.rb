class Transfer < Transaction
  belongs_to :user
  belongs_to :money_account
  belongs_to :transferer_money_account, class_name: "MoneyAccount"

  validates :user, :money_account, :transferer_money_account, presence: true

  def transfer?
    true
  end

  private

  def set_account_id
    self.account_id = user.account_id
  end
end
