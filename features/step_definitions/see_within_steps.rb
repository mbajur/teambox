{
  'in the title' => 'h2',
  'in the watchers list' => '.watching',
  'as a button' => 'a.button, button',
  'in the preview' => '.previewBox'
}.
each do |within, selector|
  Then /^(?:|I )should( not)? see "([^\"]*)" #{within}$/ do |negate, text|
    if negate
      expect(page).to have_no_css(selector, text: text)
    else
      expect(page).to have_css(selector, text: text)
    end
  end
end

Then /^I should see an error message: "([^\"]*)"$/ do |text|
  with_scope('.flash-error') do
    step %(I should see "#{text}")
  end
end

Then /^I should see a notice: "([^\"]*)"$/ do |text|
  with_scope('.flash-notice') do
    step %(I should see "#{text}")
  end
end
