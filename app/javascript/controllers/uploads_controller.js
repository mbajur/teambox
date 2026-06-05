import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uploadForm"]

  showUploadForm(e) {
    e.preventDefault();
    this.uploadFormTarget.classList.toggle('invisible');
  }
}
