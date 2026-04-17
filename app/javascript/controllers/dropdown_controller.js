import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  connect() {
    this.menu = this.element.querySelector('[role="menu"]');
    this.handleClickOutside = this.handleClickOutside.bind(this);
  }

  toggle(event) {
    event.stopPropagation();

    if (this.menu) {
      this.menu.classList.toggle('hidden');

      if (!this.menu.classList.contains('hidden')) {
        // Close other dropdowns
        document.querySelectorAll('[data-controller="dropdown"]').forEach(dropdown => {
          if (dropdown !== this.element) {
            const otherMenu = dropdown.querySelector('[role="menu"]');
            if (otherMenu && !otherMenu.classList.contains('hidden')) {
              otherMenu.classList.add('hidden');
            }
          }
        });

        document.addEventListener('click', this.handleClickOutside);
      } else {
        document.removeEventListener('click', this.handleClickOutside);
      }
    }
  }

  handleClickOutside = (event) => {
    if (!this.element.contains(event.target) && this.menu) {
      if (!this.menu.classList.contains('hidden')) {
        this.menu.classList.add('hidden');
      }
      document.removeEventListener('click', this.handleClickOutside);
    }
  }
}
