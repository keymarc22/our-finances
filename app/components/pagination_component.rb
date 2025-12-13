# frozen_string_literal: true

class PaginationComponent < ApplicationComponent
  erb_template <<~ERB
    <%== @pagy.series_nav %>
  ERB
  
  def initialize(pagy:)
    @pagy = pagy
  end

  def render?
    @pagy.pages > 1
  end
end
