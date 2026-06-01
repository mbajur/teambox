When /^the search index is re(indexed|built)$/ do |action|
  # ts_reindex is not available in this app configuration
  sleep(0.2)
end

When /^I fill in the search box with "(.+)"$/ do |value|
  When(%(I fill in "q" with "#{value}"))
end

When /^I submit the search/ do
  if Capybara.current_driver == Capybara.javascript_driver
    page.evaluate_script("document.getElementsByClassName('search')[0].submit()")
  else
    # Not Implemented yet
  end
end

Given /^there is a conversation titled "(.+)" in the project "(.+)"$/ do |title, project_name|
  FactoryBot.create(:conversation,
    name: title,
    project: Project.find_by_name(project_name)
  )
end

Given /^there is a conversation with body "(.+?)" in the project "(.+?)"$/ do |body, project_name|
  FactoryBot.create(:simple_conversation,
    body: body,
    project: Project.find_by_name(project_name)
  )
end

Given /^there is a task titled "(.+)" in the project "(.+)"$/ do |title, project_name|
  FactoryBot.create(:task,
    name: title,
    project: Project.find_by_name(project_name)
  )
end

Given /^the task titled "([^"]*)" has a file named "([^"]*)" attached$/ do |task_name, upload_name|
  task = Task.find_by_name(task_name)
  upload = FactoryBot.create(:upload, asset_file_name: upload_name)
  comment = FactoryBot.create(:comment, upload_ids: [ upload.id.to_s ], target: task)
end

Given /^the conversation titled "([^"]*)" has a file named "([^"]*)" attached$/ do |conversation_name, upload_name|
  conversation = Conversation.find_by_name(conversation_name)
  upload = FactoryBot.create(:upload, asset_file_name: upload_name)
  comment = FactoryBot.create(:comment, upload_ids: [ upload.id.to_s ], target: conversation)
end

Given /^the task titled "([^"]*)" has a google doc named "([^"]*)" attached$/ do |task_name, google_doc_name|
  task = Task.find_by_name(task_name)
  google_doc = FactoryBot.create(:google_doc, title: google_doc_name)
  comment = FactoryBot.create(:comment, google_doc_ids: [ google_doc.id.to_s ], target: task)
end

Given /^the conversation titled "([^"]*)" has a google doc named "([^"]*)" attached$/ do |conversation_name, google_doc_name|
  conversation = Conversation.find_by_name(conversation_name)
  google_doc = FactoryBot.create(:google_doc, title: google_doc_name)
  comment = FactoryBot.create(:comment, google_doc_ids: [ google_doc.id.to_s ], target: conversation)
end

When /^I search for "(.+)"$/ do |terms|
  step %(I go to the results page for "#{terms}")
end

Then /^(?:|I )should see "([^\"]*)" in the results$/ do |text|
  step %(I should see "#{text}" within "#search_results")
end

Then /^(?:|I )should not see "([^\"]*)" in the results$/ do |text|
  step %(I should not see "#{text}" within "#search_results")
end
