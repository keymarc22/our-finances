# frozen_string_literal: true

class Mobile::NavbarLinkComponent < ApplicationComponent
  attr_reader :path, :icon
  
  def initialize(path:, icon:)
    @path = path
    @icon = icon
  end
  
  def active?
    current_page?(path)
  end
end
