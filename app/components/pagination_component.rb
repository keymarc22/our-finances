# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  erb_template <<~ERB
    <%= content_tag :div, class: 'w-100 flex justify-center items-center gap-2' do %>
      <%== @pagy.series_nav %>
    <% end %>
  ERB

  def initialize(pagy:)
    @pagy = pagy
  end

  def render?
    @pagy.pages > 1
  end
end
