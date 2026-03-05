import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="currency-toggle"
export default class extends Controller {
  static targets = ["checkbox", "input", "exchangeRate", "exchangeRateInput", "usdLabel", "vesLabel"]

  toggle() {
    const isVes = this.checkboxTarget.checked

    this.inputTarget.value = isVes ? "VES" : "USD"

    if (isVes) {
      this.exchangeRateTarget.classList.remove("hidden")
      this.vesLabelTarget.classList.add("font-bold")
      this.usdLabelTarget.classList.remove("font-bold")
    } else {
      this.exchangeRateTarget.classList.add("hidden")
      this.exchangeRateInputTarget.value = ""
      this.usdLabelTarget.classList.add("font-bold")
      this.vesLabelTarget.classList.remove("font-bold")
    }
  }
}
