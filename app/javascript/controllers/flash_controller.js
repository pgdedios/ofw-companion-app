import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Trigger reflow to ensure animation works
    this.element.offsetHeight

    // Show the flash
    this.element.setAttribute("data-visible", "true")

    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.close()
    }, 5000)
  }

  close() {
    if (!this.element) return

    // Clear timeout if already closed manually
    if (this.timeout) clearTimeout(this.timeout)

    // Start exit animation
    this.element.setAttribute("data-visible", "false")
    this.element.classList.remove("translate-x-0", "opacity-100")
    this.element.classList.add("translate-x-full", "opacity-0")

    // Remove from DOM after animation
    setTimeout(() => {
      this.element.remove()
    }, 300) // Match CSS transition duration
  }
}