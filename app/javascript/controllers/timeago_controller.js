import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    var date = new Date(parseInt(this.element.getAttribute('data-msec')));
    this.element.innerHTML = date.timeAgo();
  }
}
