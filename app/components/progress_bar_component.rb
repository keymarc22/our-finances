# frozen_string_literal: true

class ProgressBarComponent < ApplicationComponent
  erb_template <<-ERB
    <div class="relative h-4 w-full overflow-hidden rounded-full bg-gray-200" <%= tag.attributes(@attrs || {}) %>>
      <div class="h-full transition-all duration-300 ease-in-out"
        style="width: <%= @calc_pixels %>%; background-color: <%= @color || 'transparent' %>;">
      </div>
    </div>
  ERB

  def initialize(percentage:, color: nil, klass: nil, **attrs)
    @percentage = percentage
    @attrs = attrs
    @klass = klass
    @calc_pixels = calc_pixels
    @color = color
  end

  private

  def calc_pixels
    [ @percentage.to_i, 100 ].min
  end
end
