class MoneyAccountTransfer
  class MoneyAccountTransferError < StandardError; end

  def self.create(user, description:, amount:, from_money_account_id:, to_money_account_id:)
    new(user, description, amount, from_money_account_id, to_money_account_id).send(:create!)
  end

  def self.update(user, transfer_id:, description:, amount:, from_money_account_id:, to_money_account_id:)
    new(user, description, amount, from_money_account_id, to_money_account_id, transfer_id).send(:update!)
  end

  def self.destroy(user, transfer_id:)
    new(user, nil, nil, nil, nil, transfer_id).send(:destroy!)
  end

  private

  attr_reader :amount, :outgoing_transfer, :from_money_account_id, :to_money_account_id, :user, :description

  def initialize(user, description = nil, amount = nil, from_money_account_id = nil, to_money_account_id = nil, transfer_id = nil)
    @user = user
    @description = description
    @amount = amount
    @from_money_account_id = from_money_account_id
    @to_money_account_id = to_money_account_id
    @outgoing_transfer = OutgoingTransfer.find(transfer_id) if transfer_id
  end

  def create!
    validate_create_params!

    from_account = MoneyAccount.find(from_money_account_id)
    to_account = MoneyAccount.find(to_money_account_id)

    if from_account.account_id != to_account.account_id
      raise "Las cuentas de origen y destino no pertenecen al mismo usuario"
    end

    if from_account.balance < Money.from_amount(amount)
      raise "Fondos insuficientes en la cuenta de origen"
    end

    ActiveRecord::Base.transaction do
      outgoing = OutgoingTransfer.create!(
        user:, description:, amount: amount * -1, money_account_id: from_money_account_id
      )
      IncomingTransfer.create!(
        user:, description:, amount:, money_account_id: to_money_account_id
      )
      outgoing
    end
  rescue => e
    Rails.logger.error("Failed to create money account transfer: #{e.message}")
    raise MoneyAccountTransferError, e.message
  end

  def update!
    raise "OutgoingTransfer not found" if @outgoing_transfer.nil?
    validate_create_params!

    incoming_transfer = find_related_incoming_transfer
    raise "IncomingTransfer relacionada no encontrada" if incoming_transfer.nil?

    from_account = MoneyAccount.find(from_money_account_id)
    to_account = MoneyAccount.find(to_money_account_id)

    if from_account.account_id != to_account.account_id
      raise "Las cuentas de origen y destino no pertenecen al mismo usuario"
    end

    ActiveRecord::Base.transaction do
      @outgoing_transfer.update!(
        user:,
        description:,
        amount: amount * -1,
        money_account_id: from_money_account_id
      )

      incoming_transfer.update!(
        user:,
        description:,
        amount:,
        money_account_id: to_money_account_id
      )

      @outgoing_transfer.reload
    end
  rescue => e
    Rails.logger.error("Failed to update money account transfer: #{e.message}")
    raise MoneyAccountTransferError, e.message
  end

  def destroy!
    raise "OutgoingTransfer not found" if @outgoing_transfer.nil?

    incoming_transfer = find_related_incoming_transfer
    raise "IncomingTransfer relacionada no encontrada" if incoming_transfer.nil?

    ActiveRecord::Base.transaction do
      incoming_transfer.destroy!
      @outgoing_transfer.destroy!
    end

    @outgoing_transfer
  rescue => e
    Rails.logger.error("Failed to destroy money account transfer: #{e.message}")
    raise MoneyAccountTransferError, e.message
  end

  def validate_create_params!
    if user.nil? || amount.nil? || from_money_account_id.nil? || to_money_account_id.nil?
      raise "Invalid data for transfer action"
    end
  end

  def find_related_incoming_transfer
    IncomingTransfer.where(
      user:,
      amount_cents: @outgoing_transfer.amount_cents * -1,
      description: @outgoing_transfer.description,
      account_id: @outgoing_transfer.account_id
    ).where(created_at: (@outgoing_transfer.created_at - 1.second)..(@outgoing_transfer.created_at + 1.second))
     .first
  end
end
