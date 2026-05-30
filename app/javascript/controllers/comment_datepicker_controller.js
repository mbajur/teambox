import {Datepicker} from 'stimulus-datepicker'
import i18n from 'utils/i18n'

export default class extends Datepicker {
  static targets = ['reset', 'urgent']
  static values = {
    isUrgent: {type: Boolean, default: false},
  }

  dateValueChanged(value, previousValue) {
    super.dateValueChanged(value, previousValue)

    this.updateToggle()
  }

  connect() {
    if (this.hasUrgentTarget) {this.isUrgentValue = this.urgentTarget.checked}
    super.connect()
  }

  updateToggle() {
    if (this.isUrgentValue) {
      this.toggleTarget.innerText = i18n.t('date_picker.urgent.short')
    } else if (this.dateValue !== '') {
      const selectedDate = new Date(this.dateValue)
      this.toggleTarget.innerText = selectedDate.strftime(i18n.t('date.formats.long'))
    } else {
      this.toggleTarget.innerText = i18n.t('date_picker.no_date_assigned')
    }
  }

  addInputAction() {
    this.addAction(this.inputTarget, 'comment-datepicker#update')
  }

  addToggleAction() {
    if (!this.hasToggleTarget) return

    let action = 'click->comment-datepicker#toggle'
    if (!(this.toggleTarget instanceof HTMLButtonElement)) action += ' keydown->comment-datepicker#toggle'

    this.addAction(this.toggleTarget, action)
  }

  urgentChanged(e) {
    this.isUrgentValue = e.target.checked
    this.urgentTarget.checked = this.isUrgentValue
    this.updateToggle()
    this.redraw()
  }

  closeOnOutsideClick(event) {
    // `event.target` could already have been removed from the DOM
    // (e.g. if the previous-month button was clicked) so we cannot
    // use `this.calendarTarget.contains(event.target)`.
    if (event.target.closest('[data-comment-datepicker-target="calendar"]')) return
    this.close(true)
  }

  clear(e) {
    e.preventDefault()
    this.dateValue = ''
    this.close(true)
  }

  addHiddenInput() {
    this.inputTarget.insertAdjacentHTML('afterend', `
      <input type="hidden"
             name="${this.inputTarget.getAttribute('name')}"
             value="${this.inputTarget.value}"
             data-comment-datepicker-target="hidden"/>
    `)
  }

  // Generates the HTML for the calendar and inserts it into the DOM.
  //
  // Does not focus the given date.
  //
  // @param isoDate [IsoDate] the date of interest
  render(isoDate, animate) {
    const urgentInput = this.hasUrgentTarget ? `
      <div class="urgent">
        <input class="urgent" type="checkbox" value="1" id="urgent" data-action="input->comment-datepicker#urgentChanged" ${this.isUrgentValue ? 'checked' : ''}/>
        <label style="display: inline-block" for="urgent">
          ${i18n.t('date_picker.urgent.long')}
        </label>
        <a href="#" class="show-help text_actions invisible">[?]</a>
        <div class="help" style="display: none">
          ${i18n.t('date_picker.urgent.info')}
        </div>
      </div>
    ` : ''

    const cal = `
      <div class="sdp-cal calendar_date_select" data-comment-datepicker-target="calendar" data-action="click@window->comment-datepicker#closeOnOutsideClick keydown->comment-datepicker#key" role="dialog" aria-modal="true" aria-label="${this.text('chooseDate')}">
        <div class="sdp-nav ${this.isUrgentValue} ${this.isUrgentValue ? 'invisible' : ''}">
          <div class="sdp-nav-dropdowns">
            <div>
              <select class="sdp-month" data-comment-datepicker-target="month" data-action="comment-datepicker#redraw">
                ${this.monthOptions(+isoDate.mm)}
              </select>
            </div>
            <div>
              <select class="sdp-year" data-comment-datepicker-target="year" data-action="comment-datepicker#redraw">
                ${this.yearOptions(+isoDate.yyyy)}
              </select>
            </div>
          </div>

          <div class="sdp-nav-buttons">
            <button class="sdp-goto-prev" data-comment-datepicker-target="prevMonth" data-action="comment-datepicker#gotoPrevMonth" title="${this.text('previousMonth')}" aria-label="${this.text('previousMonth')}">
              <svg viewBox="0 0 10 10">
                <polyline points="7,1 3,5 7,9" />
              </svg>
            </button>
            <button class="sdp-clear" data-comment-datepicker-target="clear" data-action="comment-datepicker#clear" title="${i18n.t('calendar.clear')}" aria-label="${this.text('clear')}">
              <svg viewBox="0 0 10 10">
                <line x1="0" y1="0" x2="10" y2="10" />
                <line x1="10" y1="0" x2="0" y2="10" />
              </svg>
            </button>
            <button class="sdp-goto-today" data-comment-datepicker-target="today" data-action="comment-datepicker#gotoToday" title="${this.text('today')}" aria-label="${this.text('today')}">
              <svg viewBox="0 0 10 10">
                <circle cx="5" cy="5" r="4" />
              </svg>
            </button>
            <button class="sdp-goto-next" data-comment-datepicker-target="nextMonth" data-action="comment-datepicker#gotoNextMonth" title="${this.text('nextMonth')}" aria-label="${this.text('nextMonth')}">
              <svg viewBox="0 0 10 10">
                <polyline points="3,1 7,5 3,9" />
              </svg>
            </button>
          </div>

        </div>
        <div class="sdp-days-of-week ${this.isUrgentValue} ${this.isUrgentValue ? 'invisible' : ''}">
          ${this.daysOfWeek()}
        </div>
        <div class="sdp-days ${this.isUrgentValue} ${this.isUrgentValue ? 'invisible' : ''}" data-comment-datepicker-target="days" data-action="click->comment-datepicker#pick" role="grid">
          ${this.days(isoDate)}
        </div>

        <div class="sdp-footer" style="margin-top:.5rem">
          ${urgentInput}
        </div>
      </div>
    `
    this.element.insertAdjacentHTML('beforeend', cal)
    if (animate) {
      this.calendarTarget.classList.add('fade-in')
      if (this.hasCssAnimation(this.calendarTarget)) {
        this.calendarTarget.onanimationend = e => this.calendarTarget.classList.remove('fade-in')
      } else {
        this.calendarTarget.classList.remove('fade-in')
      }
    }
  }
}
