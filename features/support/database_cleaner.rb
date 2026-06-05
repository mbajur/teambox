require 'database_cleaner'
require 'database_cleaner/active_record'

DatabaseCleaner[:active_record].strategy = :truncation

# Session cleanup is handled by an After("@javascript") hook in capybara.rb,
# which runs BEFORE DatabaseCleaner truncates the database. This prevents
# stale browser requests from hitting the server after records are deleted.

Around do |_scenario, block|
  DatabaseCleaner.cleaning do
    block.call
  end
end
