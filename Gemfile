source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use sqlite3 as the database for Active Record
gem "sqlite3", ">= 2.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.14"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails", "~> 8.0.0"
  gem "shoulda-matchers", "~> 6.0"
  gem "factory_bot_rails"
  gem "rspec_junit_formatter"
  gem "simplecov"
  gem "simplecov-cobertura"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "timecop"
  gem "rails-controller-testing"
  gem "cucumber-rails", require: false
  gem "database_cleaner"
  gem "pickle"
  gem "cuprite"
  gem "capybara-screenshot"
  gem "email_spec"
end

gem "paperclip", "~> 6.1"

gem "permalink_fu", "~> 1.0"

gem "haml-rails", "~> 2.1"

# Legacy version of sass used to compile ancient Teambox sass styles.
# We will probably move to tailwind in the future so it will not be needed.
#
# To compile sass styles, run:
# $ sass app/styles/application.sass app/assets/stylesheets/application.css
# $ sass app/styles/sessions.sass app/assets/stylesheets/sessions.css
# $ sass app/styles/sites.sass app/assets/stylesheets/sites.css
# $ sass app/styles/public_projects.sass app/assets/stylesheets/public_projects.css
# $ sass app/styles/public_downloads.sass app/assets/stylesheets/public_downloads.css
gem "sass", "3.7.4"

gem "bcrypt", "~> 3.1"

gem "rails_autolink", "~> 1.1", require: "rails_autolink/helpers"

gem "country_select", "~> 11.0"

gem "friendly_id", "~> 5.5"

gem "email_validator", "~> 2.2"

gem "rails-observers", "~> 0.1.5"

gem "oa-oauth", "~> 0.0.1"

gem "cancancan", "~> 3.6"

gem "redcarpet", "~> 3.6"

gem "i18n-js", "~> 4.2"

gem "positioning", "~> 0.4.6"

gem "search_object", "~> 1.2"

gem "pagy", "~> 9.3"
