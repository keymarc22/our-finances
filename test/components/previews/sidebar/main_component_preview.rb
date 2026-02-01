class Sidebar::MainComponentPreview < ViewComponent::Preview
  def default
    render Sidebar::MainComponent.new
  end
end
