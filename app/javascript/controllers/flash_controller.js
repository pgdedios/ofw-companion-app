import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    // Wait 3 seconds, then start fading
    setTimeout(() => {
      this.element.classList.add("opacity-0", "transition-opacity", "duration-1000");

      // Wait for the fade to complete, then remove
      setTimeout(() => {
        this.element.remove();
      }, 1000); // 1s = same as duration-1000
    }, 3000); // Visible for 3 seconds
  }
}
