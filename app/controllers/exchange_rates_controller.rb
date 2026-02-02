class ExchangeRatesController < ApplicationController
  def index
    @exchange_rates = ExchangeRatesService.run
  end
end
