import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  select() {
    this.element.classList.remove("collapsed")
    this.element.classList.add("selected")
  }

  deselect() {
    this.element.classList.remove("selected")
    this.element.classList.add("collapsed")
  }

  toggleSelect(e) {
    if (e.target.tagName === "A") {
      return // Ignore clicks on links or buttons
    }

    if (this.element.classList.contains("selected")) {
      this.deselect()
    } else {
      this.select()
    }
  }
}
