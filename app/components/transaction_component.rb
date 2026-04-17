# frozen_string_literal: true

class TransactionComponent < ApplicationComponent
  attr_reader :transaction, :budget, :options
  
  ICONS = {
    expense: 'banknote-arrow-down',
    incoming: 'banknote-arrow-up',
    incoming_transfer: 'arrow-right-left',
    outgoing_transfer: 'arrow-right-left',
  }
  
  ICON_COLOR = {
    expense: '#ff0045',
    incoming: '#05c270',
    incoming_transfer: '#027f53',
    outgoing_transfer: '#027f53',
  }

  def initialize(transaction:, **options)
    @transaction = transaction
    @budget = transaction.budget
    @options = options
  end
  
  def icon_color
    ICON_COLOR[class_name]
  end

  def icon
    ICONS[class_name]
  end
  
  def edit_url
    if transaction.expense?
      edit_expense_path(transaction)
    elsif transaction.outgoing_transfer? || transaction.incoming_transfer?
      edit_money_account_transfer_path(transaction.money_account, transaction)
    elsif transaction.incoming?
      edit_money_account_incoming_path(transaction.money_account, transaction)
    end
  end

  def delete_url
    if transaction.expense?
      expense_path(transaction)
    elsif transaction.outgoing_transfer? || transaction.incoming_transfer?
      money_account_transfer_path(transaction.money_account, transaction)
    elsif transaction.incoming?
      money_account_incoming_path(transaction.money_account, transaction)
    end
  end
  
  def class_name
    @class_name ||= transaction.class.name.underscore.to_sym
  end
end
