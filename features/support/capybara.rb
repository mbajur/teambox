require "capybara/cuprite"

# ── Inter-scenario isolation ──────────────────────────────────────────────────
#
# Problem: after a @javascript scenario finishes, the browser may have in-flight
# HTTP requests already queued in Puma. DatabaseCleaner truncates the DB *after*
# all After hooks run, so those requests hit an empty DB and produce
# RecordNotFound errors that Capybara captures in its server middleware. The next
# scenario then fails immediately when Capybara raises that stored error.
#
# Two-pronged fix:
#   1. After hook  – reset the Capybara session (navigates browser away) to stop
#                    generating new requests, plus flush any captured error.
#   2. Before hook – clear any server error that slipped in during the narrow
#                    window between After-hook completion and DB truncation.
#
# After hooks run in REVERSE registration order, so registering ours BEFORE
# requiring capybara-screenshot/cucumber means:
#   a. capybara-screenshot's hook runs FIRST  → captures screenshot
#   b. our After hook runs LAST               → resets browser

After("@javascript") do
  begin
    Capybara.current_session.reset!
  rescue Ferrum::DeadBrowserError, Ferrum::Error
    # Chrome crashed – restart so subsequent scenarios get a fresh browser.
    Capybara.current_session.driver.browser.restart rescue nil
  rescue StandardError
    nil
  ensure
    # Defensively clear the server error.  reset! -> raise_server_error! already
    # does this, but it is skipped when driver.reset! itself raises first.
    Capybara.current_session.server&.reset_error!
  end
end

# Clear any residual server error that arrived in the gap between the previous
# scenario's After hook and DatabaseCleaner's truncation.
Before("@javascript") do
  Capybara.current_session.server&.reset_error!
end

# Reset the community-mode flag after every scenario so that community_mode.feature
# does not leak `Rails.configuration.teambox.community = true` into subsequent
# features.  The step "I am using the community version" sets it to true and
# nothing ever resets it, causing organisation uniqueness validations to fail
# in unrelated tests that run later.
After do
  Rails.configuration.teambox.community = nil
end

require 'capybara-screenshot/cucumber'

Capybara::Screenshot.prune_strategy = :keep_last_run

Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = ENV["CI"] ? 10 : 5
Capybara.register_driver(:cuprite) do |app|
  opts = {
    window_size: [ 1200, 800 ],
    timeout: 30
  }

  if ENV["CI"]
    opts.merge!(
      browser_options: {
        "no-sandbox": nil,
        "disable-dev-shm-usage": nil,
        "disable-gpu": nil
      },
      process_timeout: 60
    )
  end

  opts.merge!(
    headless: false,
    slowmo: 0.3
  ) if ENV["DEBUG"]

  Capybara::Cuprite::Driver.new(app, opts)
end
