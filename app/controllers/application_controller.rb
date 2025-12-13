class ApplicationController < ActionController::Base
  include Pagy::Method
  before_action :authenticate_user!

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  private

  helper_method :current_account
  def current_account
    @current_account ||= current_user.account
  end

  helper_method :current_date_range
  def current_date_range
    @current_date_range ||= Date.current.beginning_of_month.. Date.current.end_of_month
  end
end
