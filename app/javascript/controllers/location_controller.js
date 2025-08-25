import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "output", "savedAddress", "lat", "lng", "locationField"]

  loadCoordinates() {
    const selected = this.typeTargets.find(r => r.checked).value;

    const updateFields = (lat, lng) => {
      this.latTarget.value = lat;
      this.lngTarget.value = lng;
      this.locationFieldTarget.value = `${lat},${lng}`;
      this.outputTarget.textContent = `Latitude: ${lat}, Longitude: ${lng}`;
    };

    if (selected === "current") {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition((position) => {
          updateFields(position.coords.latitude, position.coords.longitude);
        }, () => {
          this.outputTarget.textContent = "Unable to retrieve your location.";
        });
      } else {
        this.outputTarget.textContent = "Geolocation is not supported by your browser.";
      }
    } else {
      const address = this.savedAddressTarget.value;
      fetch(`/geocode_address?address=${encodeURIComponent(address)}`)
        .then(response => response.json())
        .then(data => {
          if (data.lat && data.lng) {
            updateFields(data.lat, data.lng);
          } else {
            this.outputTarget.textContent = "Could not geocode the saved address.";
          }
        });
    }
  }
}
