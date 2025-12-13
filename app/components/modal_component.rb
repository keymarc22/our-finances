# frozen_string_literal: true

class ModalComponent < ApplicationComponent
  def initialize(klass: "")
    @klass = klass
  end
end
