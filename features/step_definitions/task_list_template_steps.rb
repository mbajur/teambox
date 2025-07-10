Then /^(?:|I )should see "([^\"]*)" as the template name$/ do |text|
  step %(I should see '#{text}' within '.task_list_templates .name')
end

Then /^(?:|I )should see "([^\"]*)" as a template task name$/ do |text|
  step %(I should see '#{text}' within '.task_list_templates .title')
end

Then /^(?:|I )should see "([^\"]*)" as a template task description/ do |text|
  step %(I should see '#{text}' within '.task_list_templates .desc')
end

Given /^(?:|I )have a task list template called "([^\"]*)"$/ do |name|
  project = @current_project || FactoryBot.create(:project)
  task_list_template = FactoryBot.create(:complete_task_list_template, organization: project.organization, name: name)
end
