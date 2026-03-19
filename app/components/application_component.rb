# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :lucide_icon, :current_user, :turbo_frame_tag, :tw, :search_form_for, to: :helpers
end
