Given /^the database is empty$/ do
  DatabaseCleaner.clean_with(:truncation)
end
