# frozen_string_literal: true

class OverlayComponent < ApplicationComponent
  erb_template <<-ERB
    <div
      <%= tag.attributes(@attrs) %>
      class="<%= @klass%>">
    </div>
  ERB

  def initialize(klass: nil, **attrs)
    @attrs = attrs
    @klass = klass
  end
end
