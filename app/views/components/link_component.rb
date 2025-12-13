# class LinkComponent < Phlex::HTML
#   include Phlex::Rails::Helpers::ContentFor
#
#   VARIANTS = {
#     default: "", # Default a tag
#     pill: "rounded-md font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-750 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 flex-1 text-center px-4 py-2 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-300 transition-colors duration-200 ease-in-out whitespace-nowrap sm:text-base md:px-6 md:py-3"
#   }.freeze
#
#   def initialize(variant: :default, class: nil, **attrs)
#     @variant = variant
#     @class = binding.local_variable_get(:class)
#     @attrs = attrs
#   end
#
#   def view_template(&block)
#     a(
#       class: [
#         "cursor-pointer inline-flex items-center justify-center whitespace-nowrap text-sm #{VARIANTS[@variant]}",
#         VARIANTS[@variant],
#         @class
#       ].compact.join(" "),
#       **@attrs,
#       &block
#     )
#   end
# end
