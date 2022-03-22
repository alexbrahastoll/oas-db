require 'json'

seeds = ['incident_response.json', 'payment.json', 'project_management.json']
spec_issues = ['invalid_examples']
api_issues = ['invalid_payload', 'unexpected_payload_root_node', 'payload_missing_keys', 'payload_extra_keys',
  'payload_wrong_data_types', 'broken_record_deletion']

configs = []
seeds.each do |s|
  configs << {
    oas_seed_abs_path: "/Users/alexbrahastoll/Projects/mestrado/oas_db/sample_seeds/#{s}",
    mock_api_server_url: 'http://localhost:3000',
    spec_issues: spec_issues,
    api_issues: [],
    generated_files_basename: "#{s.split('.').first}_#{spec_issues.first}"
  }

  api_issues.each do |api_issue|
    configs << {
      oas_seed_abs_path: "/Users/alexbrahastoll/Projects/mestrado/oas_db/sample_seeds/#{s}",
      mock_api_server_url: 'http://localhost:3000',
      spec_issues: [],
      api_issues: [api_issue],
      generated_files_basename: "#{s.split('.').first}_#{api_issue}"
    }
  end
end

configs.each do |config|
  File.write("restest_experiment/config/#{config[:generated_files_basename]}.config.json", JSON.generate(config))
end
