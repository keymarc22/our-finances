class ToastComponent < ApplicationComponent
  attr_reader :message, :type, :auto_hide, :timeout, :options

  def initialize(message:, type: :info, auto_hide: true, timeout: 5000, **options)
    @message = message
    @type = toast_type_for type.to_sym
    @auto_hide = auto_hide
    @timeout = timeout
    @options = options || {}
  end

  def toast_type_for(flash_key)
    case flash_key.to_sym
    when :notice, :success
      :success
    when :alert, :error
      :error
    when :warning
      :warning
    else
      :info
    end
  end

  def variant_classes
    case @type
    when :success
      "bg-green-50 text-green-800 ring-green-600/10"
    when :error
      "bg-red-50 text-red-800 ring-red-600/10"
    when :warning
      "bg-yellow-50 text-yellow-800 ring-yellow-600/10"
    else
      "bg-white text-slate-800 ring-slate-600/6"
    end
  end

  def icon_svg
    case @type
    when :success
      "badge-check"
    when :error
      "shield-x"
    when :warning
      "shield-alert"
    else
      "bell"
    end
  end

  def text_color
    case @type
    when :success
      "text-green-600"
    when :error
      "text-red-700"
    when :warning
      "text-yellow-600"
    else
      "text-slate-600"
    end
  end
end
