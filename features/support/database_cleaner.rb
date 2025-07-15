require 'database_cleaner'
require 'database_cleaner/active_record'
require 'database_cleaner/cucumber'

DatabaseCleaner.strategy = :truncation

Around do |scenario, block|
  DatabaseCleaner.cleaning(&block)
end
