require 'timecop'

After do
  Timecop.return
end

Given /^today is "([^\"]*)"$/ do |date|
  Timecop.freeze(Date.parse(date))
end

Given /^today is ([a-z]+)$/i do |day|
  target_wday = %w[sun mon tue wed thu fri sat].index(day[0, 3].downcase)
  now = Time.now
  Timecop.freeze(now.advance(days: target_wday - now.wday))
end

Given /^the time is "([^\"]*)"$/ do |time|
  Timecop.freeze(Time.parse(time))
end

Given /^utc time is now (\d+) hours? and a bit before midnight$/ do |hours|
  time_in_future = ((Date.today + 1).to_time_in_current_zone - (60 * 60 * hours.to_i)) + 60
  Timecop.travel(time_in_future)
end

Then /^time is flowing normally again$/ do
  Timecop.return
end
