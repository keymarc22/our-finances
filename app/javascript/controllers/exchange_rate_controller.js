import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="exchange-rate"
export default class extends Controller {
  static targets = ["input", "result", "from", "to", "swapButton"]
  static values = {
    amount: Number,   // e.g. 243 (BS per USD)
    from: String,   // e.g. "USD"
    to: String      // e.g. "BS"
  }

  connect() {
    this.inverted = false
    this.setupListeners();
  }

  setupListeners() {
    this.inputTarget.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault()
        this.compute()
      }
    })
    
    this.swapButtonTarget.addEventListener('click', this.invert.bind(this));
  }
  
  compute() {
    const inputVal = parseFloat(this.inputTarget.value || "0")
    if (isNaN(inputVal)) {
      this.resultTarget.textContent = "—"
      return
    }
    
    // input is in `to` (BS) and we want `from` (USD): USD = BS / rate
    let output;
    if (this.inverted) {
      output = inputVal / this.amountValue
    } else {
      // input is in `from` (USD) and we want `to` (BS): BS = USD * rate
      output = inputVal * this.amountValue
    }

    // format to sensible decimals
    this.resultTarget.textContent = this.formatNumber(output)
  }

  // Called when user clicks the invert button (data-action="click->currency#invert")
  invert(event) {
    event && event.preventDefault()
    this.inverted = !this.inverted
    this.updateLabels()
    this.compute()
    // optional: toggle a CSS class on the invert button or container
    this.swapButtonTarget.classList.toggle("is-inverted", this.inverted)
  }

  updateLabels() {
    // Update label texts shown in the UI (swap when inverted)
    if (this.hasFromTarget) this.fromTarget.textContent = this.inverted ? this.toValue : this.fromValue
    if (this.hasToTarget) this.toTarget.textContent   = this.inverted ? this.fromValue : this.toValue
  }

  formatNumber(n) {
    // Simple formatting: trim long floats
    if (!isFinite(n)) return "—"
    if (Math.abs(n) >= 1000) return n.toLocaleString(undefined, { maximumFractionDigits: 2 })
    return Number(n.toFixed(3)).toString().replace(/\.?0+$/, "")
  }
}