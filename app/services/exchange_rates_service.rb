class ExchangeRatesService
  API_BASE = "https://ve.dolarapi.com/v1/dolares"
  
  def self.run
    rates = new.fetch_rates
    Array(rates).map { |rate| ExchangeRate.new(rate) }
  end

  def fetch_rates
    Rails.cache.fetch("exchange_rates", expires_in: 30.minutes) do
      resp = Dagger.get("#{API_BASE}")
      body = resp&.body.to_s
      
      begin
        parsed = JSON.parse(body)
        parsed.is_a?(Array) ? parsed : []
      rescue JSON::ParserError => e
        Rails.logger.warn("ExchangeRatesService: failed to parse response: #{e.message} body=#{body.inspect}")
        []
      end
    end
  end
  
  private

  def initialize; end
  
  class ExchangeRate
    attr_reader :source, :amount, :updated_at, :from, :to

    def initialize(data = {}, from: 'USD', to: 'BS')
      @source = data['fuente']
      @amount = data['promedio']
      @updated_at = data['fechaActualizacion']
      @from = from
      @to = to
    end

    def to_h
      { source:, amount:, updated_at: }
    end
  end
end
