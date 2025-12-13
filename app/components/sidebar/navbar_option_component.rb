# frozen_string_literal: true

class Sidebar::NavbarOptionComponent < ApplicationComponent
  erb_template <<-ERB
    <a href="<%= @path %>" class="sidebar-nav-item <%= @klass %>" <%= tag.attributes(@attrs) %>>
      <%= lucide_icon @icon %>
      <span class="sidebar-nav-text"><%= @label %></span>
    </a>
  ERB

  def initialize(label:, icon:, path:, klass: nil, **attrs)
    @icon = icon
    @label = label
    @path = path
    @klass = klass
    @attrs = {}
  end
end
