import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["collapseBtn", "expandBtn"]
  static values = {
    collapsed: {
      type: Boolean,
      default: true
    }
  }

  collapsedValueChanged() {
    if (this.collapsedValue) {
      this.dispatch("collapsed")
      this.collapseBtnTarget.classList.add("invisible")
      this.expandBtnTarget.classList.remove("invisible")
    } else {
      this.dispatch("expanded")
      this.collapseBtnTarget.classList.remove("invisible")
      this.expandBtnTarget.classList.add("invisible")
    }
  }

  expand(e) {
    e.preventDefault()
    this.collapsedValue = false
  }

  collapse(e) {
    e.preventDefault()
    this.collapsedValue = true
  }
}
