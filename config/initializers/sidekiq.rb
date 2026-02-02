# Configure Redis URL for Sidekiq
# In test environment, use default localhost Redis if credentials are not available
redis_url = if Rails.env.test?
  ENV.fetch("REDIS_URL", "redis://localhost:6379/0")
else
  Rails.application.credentials.dig(Rails.env.to_sym, :redis_url)
end

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
