import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs";

String.prototype.incrementLastNumber = function () {
  var i = 0, matches = this.match(/\d+/g);
  matches.push(parseInt(matches.pop()) + 1);
  return this.replace(/\d+/g, function (m) { return matches[i++]; });
}

export default class extends Controller {
  static targets = ["bodyInput", "privacyArea", "uploadArea", "watchersArea"]
  static values = {
    usersToMention: {
      type: Array,
      default: []
    }
  }

  connect() {
    super.connect();
    this.tribute = new Tribute({
      collection: [{
        trigger: '@',
        values: this.usersToMentionValue
      }]
    });

    this.tribute.attach(this.bodyInputTarget);
  }

  togglePrivacy(e) {
    e.preventDefault()
    this.privacyAreaTarget.classList.toggle("invisible")
  }

  toggleUpload(e) {
    e.preventDefault()
    this.uploadAreaTarget.classList.toggle("invisible")
  }

  toggleWatchers(e) {
    e.preventDefault()
    this.watchersAreaTarget.classList.toggle("invisible")
  }

  onUploadChanged(e) {
    var newInput = document.createElement('input');
    newInput.type = 'file';
    newInput.name = e.target.name.incrementLastNumber();
    newInput.setAttribute('data-action', 'change->comment#onUploadChanged');

    if (!this.hasEmptyFileUploads(e.target.form)) {
      e.target.insertAdjacentElement('afterend', newInput);
    }
  }

  onAddWatcher(e) {
    e.preventDefault();
    this.bodyInputTarget.value += `@${e.currentTarget.dataset.login} `;
  }

  hasEmptyFileUploads(form) {
    const fileInputs = form.querySelectorAll('input[type="file"]');
    for (let input of fileInputs) {
      if (input.files.length === 0) {
        return true; // Found at least one empty file input
      }
    }
    return false; // All file inputs have files
  }
}
