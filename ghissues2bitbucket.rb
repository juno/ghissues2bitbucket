# -*- coding: utf-8 -*-
require 'faraday'
require 'multi_json'

if ARGV.size < 1
  puts "Usage: bundle exec ruby #{$0} [JSON] [USERNAME] [PASSWORD] [REPO_USERNAME] [REPO_SLUG]"
  puts "       JSON          - Path for db-1.0.json file"
  puts "       USERNAME      - BitBucket username to use"
  puts "       PASSWORD      - BitBucket password to use"
  puts "       REPO_USERNAME - BitBucket repository username"
  puts "       REPO_SLUG     - BitBucket repository slug name"
  exit
end

# initialize
json = MultiJson.load(File.open(ARGV[0]).read, symbolize_keys: true)
username = ARGV[1]
password = ARGV[2]
repo_accountname = ARGV[3]
repo_slug = ARGV[4]

# info
puts "Number of issues: #{json[:issues].size}"

# setup faraday
api = Faraday.new(url: 'https://api.bitbucket.org') do |faraday|
  faraday.request  :url_encoded
  # Print HTTP log to STDOUT
  #faraday.response :logger
  faraday.adapter  Faraday.default_adapter
end
api.basic_auth(username, password)

# import milestones
sorted_milestones = json[:issues].map{ |i| i[:milestone] }.reject{ |i| i.nil? }.uniq
# fetch defined milestones
path = "/1.0/repositories/#{repo_accountname}/#{repo_slug}/issues/milestones"
response_body = api.get(path).body
defined_milestones = MultiJson.load(response_body, symbolize_keys: true).map{ |i| i[:name] }
# create not defined milestones
sorted_milestones.each do |milestone|
  next if defined_milestones.include?(milestone)
  path = "/1.0/repositories/#{repo_accountname}/#{repo_slug}/issues/milestones"
  api.post(path, { name: milestone })
  puts "Milestone #{milestone} created"
end

# create comments hash
comments = json[:comments]

# import issues
sorted_issues = json[:issues].sort_by { |item| item[:id] }

# create not created issues
sorted_issues.each do |issue|
  path = "/1.0/repositories/#{repo_accountname}/#{repo_slug}/issues"
  params = {
    status: issue[:status],
    priority: issue[:priority],
    title: issue[:title],
    responsible: issue[:assignee],
    content: "(Originally reported by #{issue[:reporter]})\r\n\r\n" + issue[:content],
    milestone: issue[:milestone],
    # TODO: version
  }
  response_body = api.post(path, params).body
  puts "Issue #{params[:title]} created"
  local_id = MultiJson.load(response_body, symbolize_keys: true)[:local_id]

  # import comments
  comments_for_issue = comments.select { |i| i[:issue].to_i == issue[:id].to_i }
  comments_for_issue.each do |comment|
    path = "/1.0/repositories/#{repo_accountname}/#{repo_slug}/issues/#{local_id}/comments"
    params = {
      content: "(Originally commented by #{comment[:user]})\r\n\r\n" + comment[:content],
    }
    api.post(path, params)
    puts "  Comment created"
  end
end
