class ProgressBarComponentPreview < ViewComponent::Preview
  # @!group Progress Bar
  def default
    render ProgressBarComponent.new(percentage: 45, color: "#4F46E5")
  end

  def zero
    render ProgressBarComponent.new(percentage: 0, color: "#CBD5E1")
  end

  def full
    render ProgressBarComponent.new(percentage: 100, color: "#10B981")
  end

  def overflow
    render ProgressBarComponent.new(percentage: 150)
  end

  # @!endgroup
end
