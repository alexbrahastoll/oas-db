require 'json'

# seeds = ['incident_response.json', 'payment.json', 'project_management.json']
seeds = ['payment.json']
spec_issues = ['broken_record_deletion']
api_issues = []

configs = []
seeds.each do |s|
  configs << {
    oas_seed_abs_path: "/Users/alexbrahastoll/Projects/mestrado/oas_db/sample_seeds/#{s}",
    mock_api_server_url: 'http://localhost:3000',
    spec_issues: spec_issues,
    api_issues: api_issues,
    generated_files_basename: s.split('.').first
  }
end

configs.each do |config|
  File.write("restest_experiment/config/#{config[:generated_files_basename]}.config.json", JSON.generate(config))
end
