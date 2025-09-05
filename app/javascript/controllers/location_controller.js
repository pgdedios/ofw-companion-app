import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "radius", "keyword"]

  connect() {
    console.log("LocationController connected")
  }

  search(event) {
    event.preventDefault()

    if (!navigator.geolocation) {
      alert("Geolocation is not supported by your browser.")
      return
    }

    const onSuccess = (position) => {
      const { latitude: lat, longitude: lng } = position.coords
      const radius = this.radiusTarget.value || "5000"
      const keyword = this.keywordTarget.value || "remittance center"

      const url = new URL(this.formTarget.action, window.location.origin)
      url.searchParams.set("location", `${lat},${lng}`)
      url.searchParams.set("radius", radius)
      url.searchParams.set("keyword", keyword)

      console.log("🔍 Searching near:", url.toString())
      Turbo.visit(url)
    }

    const onError = (error) => {
      let message = "Unable to retrieve your location."
      switch (error.code) {
        case error.PERMISSION_DENIED:
          message = "Please allow location access in your browser settings."
          break
        case error.POSITION_UNAVAILABLE:
          message = "Location information is unavailable. Check GPS or network."
          break
        case error.TIMEOUT:
          message = "Location request timed out. Please try again."
          break
        default:
          message += " Check your internet connection."
      }
      alert(message)
      console.error("Geolocation error:", error)
    }

    navigator.geolocation.getCurrentPosition(onSuccess, onError, {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 60000
    })
  }
}
