When /^(?:|I )fill in the comment box with "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, selector|
  with_scope(selector) do
    field = first(:css, 'textarea[name*="[body]"], textarea[name*="comment[body]"], form.new_comment textarea, form.edit_comment textarea', visible: :visible)
    raise Capybara::ElementNotFound, 'Unable to find a visible comment textarea' unless field
    field.set(value)
  end
end

When /^(?:|I )fill in the last comment box with "([^\"]*)"(?: within "([^\"]*)")?$/ do |value, selector|
  with_scope(selector) do
    expect(page).to have_xpath('//textarea[contains(@name, \'[body]\')]')
    all(:xpath, '//textarea[contains(@name, \'[body]\')]').last.click
    all(:xpath, '//textarea[contains(@name, \'[body]\')]').last.set(value)
  end
end

When /^I fill in the comment box with line breaks$/ do
  text = "Text with\na break"
  find(:xpath, '//textarea[contains(@name, \'[body]\')]').set(text)
end

When /^I fill in the comment box with underscored words and links$/ do
  text = "_Text_ with an underscored_long_word and a link:\nhttp://teambox.com or an email: jordi@teambox.com"
  find(:xpath, '//textarea[contains(@name, \'[body]\')]').set(text)
end
