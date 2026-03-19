# frozen_string_literal: true

class CardComponent < ApplicationComponent
  attr_reader :title, :subtitle, :icon, :klass, :footer, :url, :options

  def initialize(title: nil, subtitle: nil, footer: nil, icon: nil, url: nil, **options)
    @title = title
    @subtitle = subtitle
    @icon = icon
    @klass = klass
    @url = url
    @options = options
  end
end
