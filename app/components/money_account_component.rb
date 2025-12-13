# frozen_string_literal: true

class MoneyAccountComponent < ApplicationComponent
  attr_reader :money_account
  
  def initialize(money_account:)
    @money_account = money_account
  end
end
