# frozen_string_literal: true

class BadgeComponent < ApplicationComponent
  BASE_CLASS = "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
  
  erb_template <<~ERB
    <%= content_tag :div, class: badge_classes, style: @style, **@options do
      @text
    end %>
  ERB
  
  def initialize(text:, variant: :default, data: nil, style: nil, options: {})
    @text = text
    @variant = variant
    @data = data
    @style = style
    @options = options
  end
  
  def badge_classes
    variant_class = case @variant.to_sym
    when :default
      ComponentsHelper::PRIMARY_CLASSES
    when :secondary
      ComponentsHelper::SECONDARY_CLASSES
    when :error, :danger, :alert, :destructive
      ComponentsHelper::DESTRUCTIVE_CLASSES
    when :outline
      ComponentsHelper::OUTLINE_CLASSES
    when :ghost
      ComponentsHelper::GHOST_CLASSES
    else
      ComponentsHelper::PRIMARY_CLASSES
                    end
    
    "#{BASE_CLASS} #{variant_class}"
  end
end
