import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["reference"]

  toggleReference() {
    this.referenceTarget.style.display =
      this.referenceTarget.style.display === "none" ? "" : "none"
  }
}
