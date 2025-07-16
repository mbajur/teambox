{
  'in the title' => 'h2',
  'in the watchers list' => '.watching',
  'as a button' => 'a.button, button',
  'in the preview' => '.previewBox'
}.
each do |within, selector|
  Then /^(?:|I )should( not)? see "([^\"]*)" #{within}$/ do |negate, text|
    within(selector) do
      if page.html
        if negate
          expect(page).to_not have_content(text)
        else
          expect(page).to have_content(text)
        end
      else
        step %(I should#{negate} see "#{text}")
      end
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
