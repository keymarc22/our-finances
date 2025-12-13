# frozen_string_literal: true

class Sidebar::MainComponent < ApplicationComponent
  def render?
    current_user.present?
  end
end
