require 'database_cleaner'
require 'database_cleaner/active_record'
require 'database_cleaner/cucumber'  # registers its own Around { DatabaseCleaner.cleaning }

DatabaseCleaner.strategy = :truncation

# Between scenarios, Chrome may still dispatch in-flight requests (e.g. lazy
# ActiveStorage image loads) that arrive at the server after the database has
# been truncated. Capybara stores those server-side exceptions and re-raises
# them on the next interaction, failing an unrelated scenario. Resetting the
# session here — with the error discarded — keeps the slate clean without
# hiding errors that actually happen *during* a scenario (those are still raised
# by the After hook / reset_sessions! at the end of each scenario).
Before("@javascript") do
  Capybara.current_session.reset!
rescue StandardError
  nil # discard stale inter-scenario server errors
end
