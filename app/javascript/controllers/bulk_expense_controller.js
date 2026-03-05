import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  add(event) {
    event.preventDefault()
    const content = this.templateTarget.content.cloneNode(true)
    const index = Date.now()

    content.querySelectorAll("[data-index]").forEach((el) => {
      const name = el.getAttribute("name")
      if (name) {
        el.setAttribute("name", name.replace("NEW_INDEX", index))
      }
      el.removeAttribute("data-index")
    })

    this.listTarget.appendChild(content)
  }

  remove(event) {
    event.preventDefault()
    const row = event.target.closest("[data-bulk-expense-row]")
    if (this.listTarget.querySelectorAll("[data-bulk-expense-row]").length > 1) {
      row.remove()
    }
  }
}
