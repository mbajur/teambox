import { Application } from "@hotwired/stimulus"
import Sortable from '@stimulus-components/sortable'
import AutoSubmit from '@stimulus-components/auto-submit'
import { Datepicker } from 'stimulus-datepicker'

const application = Application.start()

application.register('sortable', Sortable)
application.register('auto-submit', AutoSubmit)
application.register('datepicker', Datepicker)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
