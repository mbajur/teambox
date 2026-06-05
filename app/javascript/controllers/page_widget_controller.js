import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "bar"]

  show(event) {
    event.preventDefault()
    const type = event.currentTarget.dataset.widgetType
    this.formTargets.forEach(form => {
      if (form.dataset.widgetForm === type) {
        form.style.display = "block"
      } else {
        form.style.display = "none"
      }
    })
    this.barTarget.style.display = "none"
  }

  cancel(event) {
    event.preventDefault()
    this.formTargets.forEach(form => {form.style.display = "none"})
    this.barTarget.style.display = ""
  }
}
