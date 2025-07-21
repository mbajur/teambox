# Pin npm packages by running ./bin/importmap

pin "application"
pin "@rails/ujs", to: "https://cdn.jsdelivr.net/npm/@rails/ujs@7.1.3-4/+esm"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
# pin "i18n-js", to: "https://esm.sh/i18n-js"
pin "i18n-js", to: "https://cdn.skypack.dev/i18n-js"
# pin "bignumber.js", to: "https://cdn.jsdelivr.net/npm/bignumber.js@9.3.1/bignumber.min.js"
pin_all_from "app/javascript/utils", under: "utils"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@stimulus-components/sortable", to: "@stimulus-components--sortable.js" # @5.0.2
pin "@rails/request.js", to: "@rails--request.js.js" # @0.0.12
pin "sortablejs" # @1.15.6
pin "@stimulus-components/auto-submit", to: "@stimulus-components--auto-submit.js" # @6.0.0
pin "stimulus-datepicker" # @1.0.9
pin "@stimulus-components/checkbox-select-all", to: "@stimulus-components--checkbox-select-all.js" # @6.1.0
