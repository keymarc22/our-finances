class ModalComponentPreview < ViewComponent::Preview
  def with_content_block
    render ModalComponent.new do
      tag.div do
        content_tag(:span, "Hello")
      end
    end
  end
end
