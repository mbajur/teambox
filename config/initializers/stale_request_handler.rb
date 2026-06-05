# frozen_string_literal: true

# StaleRequestHandler – test-environment Rack middleware
#
# Problem
# -------
# cucumber-rails prepends logic to ActionDispatch::ShowExceptions that sets
# env['action_dispatch.show_exceptions'] = :none whenever
# ActionController::Base.allow_rescue is false (the default in env.rb).  With
# :none, ShowExceptions re-raises *every* exception instead of converting it to
# an HTTP response.  This causes exceptions from stale in-flight browser
# requests (e.g. ActiveStorage blob fetches that arrive after DatabaseCleaner
# has truncated the DB) to propagate all the way to Capybara's server
# middleware, where they are *stored*.  On the next page navigation Capybara
# raises the stored error, failing the *next* scenario rather than the one
# that caused the stale request.
#
# Fix
# ---
# Insert a Rack middleware just before ActionDispatch::ShowExceptions that
# converts exceptions Rails would normally map to 4xx responses into proper
# HTTP responses.  This prevents them from reaching Capybara's error store
# while still allowing genuine application bugs (5xx) to propagate.

return unless Rails.env.test?

class StaleRequestHandler
  # Exceptions that ActionDispatch::ShowExceptions maps to 4xx responses.
  # These should become HTTP responses, not stored server errors.
  RESCUE_RESPONSES = ActionDispatch::ExceptionWrapper.rescue_responses

  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue => exception
    status_sym = RESCUE_RESPONSES[exception.class.name]
    if status_sym
      status = Rack::Utils::SYMBOL_TO_STATUS_CODE[status_sym]
      body    = "#{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"
      [ status, { "Content-Type" => "text/plain", "Content-Length" => body.bytesize.to_s }, [ body ] ]
    else
      raise
    end
  end
end

Rails.application.config.middleware.insert_before(
  ActionDispatch::ShowExceptions,
  StaleRequestHandler
)
