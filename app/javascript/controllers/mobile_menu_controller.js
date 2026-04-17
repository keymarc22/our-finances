import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "overlay"]
  static values = { swipeThreshold: 50 }

  touchStartX = 0
  touchEndX = 0

  connect() {
    this.element.addEventListener('touchstart', this.handleTouchStart.bind(this), false)
    this.element.addEventListener('touchend', this.handleTouchEnd.bind(this), false)
  }

  disconnect() {
    this.element.removeEventListener('touchstart', this.handleTouchStart.bind(this), false)
    this.element.removeEventListener('touchend', this.handleTouchEnd.bind(this), false)
  }

  handleTouchStart(e) {
    this.touchStartX = e.changedTouches[0].screenX
  }

  handleTouchEnd(e) {
    this.touchEndX = e.changedTouches[0].screenX
    this.handleSwipe()
  }

  handleSwipe() {
    const diff = this.touchEndX - this.touchStartX
    const drawer = document.querySelector('[data-mobile-menu-target="drawer"]')

    // Deslizar hacia la derecha (positivo) abre el drawer
    if (diff > this.swipeThresholdValue && this.touchStartX < 50) {
      this.open()
    }
    // Deslizar hacia la izquierda (negativo) cierra el drawer
    else if (diff < -this.swipeThresholdValue && drawer?.classList.contains('drawer-open')) {
      this.close()
    }
  }

  open() {
    const drawer = document.querySelector('[data-mobile-menu-target="drawer"]')
    const overlay = document.querySelector('[data-mobile-menu-target="overlay"]')

    if (drawer) {
      drawer.classList.add("drawer-open")
    }
    if (overlay) {
      overlay.classList.add("drawer-open")
    }
    document.body.classList.add("drawer-open")
  }

  close() {
    const drawer = document.querySelector('[data-mobile-menu-target="drawer"]')
    const overlay = document.querySelector('[data-mobile-menu-target="overlay"]')

    if (drawer) {
      drawer.classList.remove("drawer-open")
    }
    if (overlay) {
      overlay.classList.remove("drawer-open")
    }
    document.body.classList.remove("drawer-open")
  }

  toggle() {
    const drawer = document.querySelector('[data-mobile-menu-target="drawer"]')
    const overlay = document.querySelector('[data-mobile-menu-target="overlay"]')

    if (drawer) {
      drawer.classList.toggle("drawer-open")
      document.body.classList.toggle("drawer-open", drawer.classList.contains("drawer-open"))
    }
    if (overlay) {
      overlay.classList.toggle("drawer-open")
    }
  }
}
