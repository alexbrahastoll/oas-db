require 'json'

seeds = ['incident_response.json', 'payment.json', 'project_management.json']
spec_issues = ['amorphous_uri', 'crudy_uri', 'sensitive_info_pqs']

configs = []
seeds.each do |s|
  spec_issues.each do |spec_issue|
    configs << {
      oas_seed_abs_path: "/Users/alexbrahastoll/Projects/mestrado/oas_db/sample_seeds/#{s}",
      mock_api_server_url: 'http://localhost:3000',
      spec_issues: [spec_issue],
      api_issues: [],
      generated_files_basename: "#{s.split('.').first}_#{spec_issue}"
    }
  end
end

configs.each do |config|
  File.write("static_experiment/config/#{config[:generated_files_basename]}.config.json", JSON.generate(config))
end
