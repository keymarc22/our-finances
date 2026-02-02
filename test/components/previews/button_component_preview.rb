class ButtonComponentPreview < ViewComponent::Preview
  # @!group Buttons
  def primary
    render ButtonComponent.new(
      :primary,
      text: "Click me",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Primary button clicked!')"
    )
  end

  def secondary
    render ButtonComponent.new(
      :secondary,
      text: "Click me",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Secondary button clicked!')"
    )
  end

  def destructive
    render ButtonComponent.new(
      :destructive,
      text: "Delete",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Destructive button clicked!')"
    )
  end

  def outline
    render ButtonComponent.new(
      :outline,
      text: "Click me",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Outline button clicked!')"
    )
  end

  def ghost
    render ButtonComponent.new(
      :ghost,
      text: "Click me",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Ghost button clicked!')"
    )
  end

  def link
    render ButtonComponent.new(
      :link,
      text: "Learn more",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Link button clicked!')"
    )
  end

  def pill
    render ButtonComponent.new(
      :pill,
      text: "Click me",
      data: { action: "click->button#handleClick" },
      onclick: "alert('Pill button clicked!')"
    )
  end

  # @!endgroup

  # @!group Buttons with Icons
  def icon_button
    render ButtonComponent.new(
      :primary,
      icon: "settings",
      text: "Settings",
      data: { action: "click->button#handleClick" }
    )
  end

  def icon_button_outline
    render ButtonComponent.new(
      :outline,
      icon: "settings",
      text: "Settings",
      data: { action: "click->button#handleClick" }
    )
  end

  def icon_only_button
    render ButtonComponent.new(
      :ghost,
      icon: "search",
      data: { action: "click->button#handleClick" }
    )
  end

  # @!endgroup
end
