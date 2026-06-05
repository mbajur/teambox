import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    var current = this.detectSelectedSection()
    this.hideAllContained()

    if (current) {
      this.toggleElement(current)
      this.showContainers(current)
    }
  }

  detectSelectedSection() {
    // Direct match
    var links = document.querySelectorAll('.nav_links a');
    var link = Array.from(links).filter(function(e) {
      return e.getAttribute('href') === window.location.pathname;
    }).pop();

    if (link) {
      var el = link.closest('.el');
      if (el) el.classList.add('selected');
    }

    // Close enough
    if (!link) {
      var linksArr = Array.from(document.querySelectorAll('.nav_links a'));
      var sortedLinks = linksArr.sort(function (a, b) {
        return a.getAttribute('href').length - b.getAttribute('href').length;
      });
      var closeLink = sortedLinks.filter(function (e) {
        return (window.location.pathname.indexOf(e.getAttribute('href')) > -1 && e.getAttribute('href') !== '/');
      }).pop();

      if (closeLink) {
        var el = closeLink.closest('.el');
        if (el) el.classList.add('children-selected');
      }

      link = closeLink;
    }

    if (link) return link.closest('.el');
  }

  hideAllContained() {
    document.querySelectorAll('.nav_links .contained').forEach(function (el) {
      el.classList.add('invisible');
    });
  }

  toggleElement(el, effect) {
    var contained = el.nextElementSibling;
    // if next element is an expanded area..
    if (contained && contained.classList.contains('contained')) {
      if (el.classList.contains('expanded')) {
        // contract it if it's open
        el.classList.remove('expanded');
        contained.classList.add('invisible');
      } else {
        // contract others if open
        var parent = el.parentElement;
        var visible_containers = Array.from(parent.querySelectorAll('.contained')).filter(e => !e.classList.contains('invisible'));
        visible_containers.forEach(e => { e.classList.add('invisible'); });
        parent.querySelectorAll('.el').forEach(e => e.classList.remove('expanded'));
        // expand the selected one
        el.classList.add('expanded');

        contained.classList.remove('invisible');
      }
      // Stop the event and don't follow the link
      return true;
    }
    // Stop the event if it's selected (don't follow the link)
    return el.classList.contains('selected');
  }

  showContainers(current) {
    var container = current.closest('.contained');
    while (container) {
      container.classList.remove('invisible');
      var prevEl = container.previousElementSibling;
      if (prevEl && prevEl.classList.contains('el')) {
        prevEl.classList.add('expanded');
      }
      container = container.parentElement ? container.parentElement.closest('.contained') : null;
    }
  }
}
