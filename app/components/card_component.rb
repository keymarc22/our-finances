# frozen_string_literal: true

class CardComponent < ApplicationComponent
  attr_reader :title, :subtitle, :icon, :klass, :footer, :options

  def initialize(title: nil, subtitle: nil, footer: nil, icon: nil, **options)
    @title = title
    @subtitle = subtitle
    @icon = icon
    @klass = klass
    @options = options
  end
end
