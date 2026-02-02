# frozen_string_literal: true

class ButtonComponent < ApplicationComponent
  THEMES = {
    primary: "bg-gray-950 text-white hover:bg-gray-800",
    secondary: "bg-gray-400 text-white hover:bg-gray-100/80",
    destructive: "bg-red-500 text-gray-50 hover:bg-red-500/90",
    outline: "border border-gray-200 bg-white hover:bg-gray-100 hover:text-gray-900",
    ghost: "hover:bg-gray-100 hover:text-gray-900",
    link: "text-gray-900 underline-offset-4 hover:underline",
    pill: "flex-1 text-center px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-300 transition-colors duration-200 ease-in-out whitespace-nowrap sm:text-base md:px-6 md:py-3"
  }.freeze

  SIZES = {
    default: "h-10 px-4 py-2",
    sm: "h-9 px-3",
    lg: "h-11 px-8",
    icon: "h-10 w-10"
  }.freeze

  BASE_CLASS = "cursor-pointer gap-1 inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-750 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"

  erb_template <<-ERB
    <button class="<%= @classes %>" <%= tag.attributes(@attrs) %>>
      <% if content.present? %>
        <%= content %>
      <% else %>
        <%= @text %>

        <% if @icon %>
          <span><%= helpers.lucide_icon(@icon, class: "h-4 w-4") %></span>
        <% end %>
      <% end %>
    </button>
  ERB

  def initialize(theme:, text: nil, icon: nil, size: :default, klass: nil, **attrs)
    @text = text
    @icon = icon
    @attrs = attrs
    @attrs[:type] ||= "button"
    @classes = [ BASE_CLASS, THEMES[theme], SIZES[size], klass ].compact.join(" ")
  end
end
