When /^I wait for ([\d\.]+) seconds?$/ do |secs|
  sleep(secs.to_f)
end

When /^I reveal all action menus$/ do
  evaluate_script("document.querySelectorAll('.actions_menu .extra').forEach(function(e){ e.style.display = 'block'; });")
end

When /^I hide all action menus$/ do
  evaluate_script("document.querySelectorAll('.actions_menu .extra').forEach(function(e){ e.style.display = null; });")
end
