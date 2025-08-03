import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editLink", "uneditableTpl"]
  static values = {
    editableBefore: { type: Number, default: 0 },
    isAdmin: { type: Boolean, default: false }
  }

  refreshEditLinkVisibility() {
    let now = new Date()
    let editableBefore = new Date(parseInt(this.editableBeforeValue))

    if (now >= editableBefore && !this.isAdminValue) {
      this.editLinkTarget.outerHTML = this.uneditableTplTarget.innerHTML
    }
  }
}
