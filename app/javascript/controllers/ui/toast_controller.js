import { Controller } from "@hotwired/stimulus"

/**
 * Toast Controller
 * 
 * Handles toast notification animations - slide in from right on appear,
 * slide out to right on dismiss. Also manages auto-hide functionality.
 * 
 * Targets:
 *   - toast: The main toast element
 * 
 * Values:
 *   - autoHide: boolean (default: true) - Whether to auto-hide the toast
 *   - timeout: number (default: 5000) - Time in ms before auto-hiding
 * 
 * Actions:
 *   - hide: Manually hide the toast with slide-out animation
 */
export default class extends Controller {
  static targets = ["toast"]
  static values = {
    autoHide: { type: Boolean, default: true },
    timeout: { type: Number, default: 5000 }
  }

  connect() {
    // Trigger slide-in animation on connect
    this.show()
    
    // Setup auto-hide if enabled
    if (this.autoHideValue) {
      this.timeoutId = setTimeout(() => {
        this.hide()
      }, this.timeoutValue)
    }
  }

  disconnect() {
    // Clear timeout if component is disconnected
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
  }

  /**
   * Show the toast with slide-in animation from right
   */
  show() {
    const element = this.element
    
    // Start with hidden state (off-screen to the right)
    element.style.transform = 'translateX(100%)'
    element.style.opacity = '0'
    
    // Trigger animation on next frame
    requestAnimationFrame(() => {
      element.style.transition = 'transform 0.3s ease-out, opacity 0.3s ease-out'
      element.style.transform = 'translateX(0)'
      element.style.opacity = '1'
    })
  }

  /**
   * Hide the toast with slide-out animation to right
   * Called when user clicks close button or auto-hide triggers
   */
  hide() {
    const element = this.element
    
    // Clear auto-hide timeout if manually hiding
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
    }
    
    // Slide out to the right
    element.style.transition = 'transform 0.3s ease-in, opacity 0.3s ease-in'
    element.style.transform = 'translateX(100%)'
    element.style.opacity = '0'
    
    // Remove element from DOM after animation completes
    element.addEventListener('transitionend', () => {
      element.remove()
    }, { once: true })
  }
}
