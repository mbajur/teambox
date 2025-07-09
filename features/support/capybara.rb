require "capybara/cuprite"
require 'capybara-screenshot/cucumber'

Capybara.javascript_driver = :cuprite
Capybara.register_driver(:cuprite) do |app|
  opts = {
    window_size: [ 1200, 800 ]
  }

  opts.merge!(
    headless: false,
    slowmo: 1
  ) if ENV['DEBUG']

  Capybara::Cuprite::Driver.new(app, opts)
end
