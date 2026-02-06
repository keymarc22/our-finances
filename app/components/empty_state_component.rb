# frozen_string_literal: true

class EmptyStateComponent < ApplicationComponent
  def initialize(title: nil, description: nil, button_text: nil, **options)
    @title = title
    @description = description
    @button_text = button_text
    @options = options
  end
end