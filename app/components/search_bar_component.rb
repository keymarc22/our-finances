# frozen_string_literal: true

class SearchBarComponent < ApplicationComponent
  SELECT_CLASSES = "h-10 w-full rounded-md border border-gray-300 bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"

  def initialize(q:, url:, search_field: :description_cont, amount_field: :amount_decimal_eq, placeholder: "Search by description", turbo_frame: "_top", filters: [])
    @q = q
    @url = url
    @search_field = search_field
    @amount_field = amount_field
    @placeholder = placeholder
    @turbo_frame = turbo_frame
    @filters = filters
  end

  private

  def has_active_filters?
    @q.conditions.any?
  end
end
