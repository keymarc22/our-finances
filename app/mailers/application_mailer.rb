class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:mailer, :default_from)
  layout "mailer"
end
