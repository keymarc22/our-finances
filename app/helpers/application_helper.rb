module ApplicationHelper
  def to_money_format(amount)
    if amount.is_a?(Money)
      amount.format
    elsif amount.is_a?(Numeric)
      Money.new(amount).format
    else
      raise ArgumentError, "Amount must be a Numeric or Money object"
    end
  end

  def label_classes
    "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
  end

  def link_as_button_classes(type = :primary)
    case type
    when :primary
      "items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-750 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-gray-950 text-white hover:bg-gray-800 h-10 px-4 py-2"
    when :secondary
      "items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-white transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-gray-750 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 bg-gray-100 text-gray-900 hover:bg-gray-100/80 h-10 px-4 py-2"
    end
  end

  def select_classes
    "mt-1 h-10 w-full rounded-md border border-gray-300 bg-background text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 select"
  end

  def mobile_primary_action_classes
    "fixed bottom-6 right-6 z-40 flex items-center justify-center w-14 h-14 rounded-full bg-blue-600 text-white shadow-lg hover:bg-blue-700 transition-colors md:hidden"
  end

  def render_turbo_stream_flash_messages(layout = "layouts/alerts")
    turbo_stream.prepend "toasts", partial: layout
  end

  def vue3_script_tag
    %(<script src="https://cdnjs.cloudflare.com/ajax/libs/vue/3.5.13/vue.global.prod.min.js"></script>).html_safe
  end
end
