import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['privateContent', 'personInput']
  static values = {
    isPrivate: {
      type: Boolean,
      default: false
    }
  }

  isPrivateValueChanged() {
    if (!this.hasPrivateContentTarget) return
    const watcherContainer = this.element.closest('form')?.querySelector('.watchers')
    if (this.isPrivateValue) {
      this.privateContentTarget.classList.remove('invisible')
      this.enablePersonInputs()
      if (watcherContainer) watcherContainer.classList.add('invisible')
    } else {
      this.privateContentTarget.classList.add('invisible')
      this.disablePersonInputs()
      if (watcherContainer) watcherContainer.classList.remove('invisible')
    }
  }

  switchToPublic(event) {
    this.isPrivateValue = false
  }

  switchToPrivate(event) {
    this.isPrivateValue = true
  }

  enablePersonInputs() {
    this.personInputTargets.forEach((input) => {input.disabled = false})
  }

  disablePersonInputs() {
    this.personInputTargets.forEach((input) => {input.disabled = true})
  }
}
