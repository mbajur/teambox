import { Application } from "@hotwired/stimulus"
import Sortable from '@stimulus-components/sortable'
import AutoSubmit from '@stimulus-components/auto-submit'
import CheckboxSelectAll from '@stimulus-components/checkbox-select-all'
import { Datepicker } from 'stimulus-datepicker'

const application = Application.start()

application.register('sortable', Sortable)
application.register('auto-submit', AutoSubmit)
application.register('checkbox-select-all', CheckboxSelectAll)
application.register('datepicker', Datepicker)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
