require 'database_cleaner'
require 'database_cleaner/active_record'
require 'database_cleaner/cucumber'  # registers its own Around { DatabaseCleaner.cleaning }

DatabaseCleaner.strategy = :truncation

# Session cleanup is handled by an After("@javascript") hook in capybara.rb,
# which runs BEFORE DatabaseCleaner truncates the database. This prevents
# stale browser requests from hitting the server after records are deleted.
