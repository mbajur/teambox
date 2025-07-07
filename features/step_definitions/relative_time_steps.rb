When /I previously posted the following comments?:?$/ do |table|
  mislav = User.find_by_login('mislav')
  project = mislav.projects.first
  conversation = (project.conversations.first || FactoryBot.create(:conversation, name: 'Testing date', project: project, user: mislav))
  table.hashes.each do |hash|
    reg = hash['relative_time'].match(/(\d+)\s(\w+)\s[a][g][o]/)
    comment_time = Integer(reg[1]).send(reg[2].to_sym).ago
    body = hash['body'] || "Just finished posting this comment (#{comment_time})"
    FactoryBot.create(:comment, project: project, user: mislav, target: conversation, created_at: comment_time, body: body)
  end
end

Then /^I should see the following time representations?:$/ do |table|
  table.hashes.each do |hash|
    expect(page).to have_content(hash['formatted_relative_time'])
  end
end
