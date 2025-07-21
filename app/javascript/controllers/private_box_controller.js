import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['privateContent', 'personInput']
  static values = {
    isPrivate: {
      type: Boolean,
      default: false
    }
  }

  isPrivateValueChanged() {
    if (this.isPrivateValue) {
      this.privateContentTarget.classList.remove('invisible')
      this.enablePersonInputs()
    } else {
      this.privateContentTarget.classList.add('invisible')
      this.disablePersonInputs()
    }
  }

  switchToPublic(event) {
    event.preventDefault()
    this.isPrivateValue = false
  }

  switchToPrivate(event) {
    console.log('elo')
    event.preventDefault()
    this.isPrivateValue = true
  }

  enablePersonInputs() {
    this.personInputTargets.forEach((input) => { input.disabled = false })
  }

  disablePersonInputs() {
    this.personInputTargets.forEach((input) => { input.disabled = true })
  }
}
