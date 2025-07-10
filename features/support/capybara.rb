require "capybara/cuprite"
require 'capybara-screenshot/cucumber'

Capybara::Screenshot.prune_strategy = :keep_last_run

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  opts = {
    window_size: [ 1200, 800 ]
  }

  opts.merge!(
    headless: false,
    slowmo: 0.3
  ) if ENV['DEBUG']

  Capybara::Cuprite::Driver.new(app, opts)
end
