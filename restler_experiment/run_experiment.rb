require 'fileutils'

home = '/root'
restler_drop_dir = File.join(home, 'restler-fuzzer-bin')
restler_binary_path = File.join(restler_drop_dir, 'restler')
restler_quick_start_script_path = File.join(home, 'restler-fuzzer')
restler_grammar_file = File.join(home, 'restler-fuzzer', 'restler_working_dir', 'Compile', 'grammar.py')
restler_dict_file = File.join(home, 'restler-fuzzer', 'restler_working_dir', 'Compile', 'dict.json')
samples_dir = File.join(home, 'oas_db', 'samples')
annotations_dir = File.join(home, 'oas_db', 'annotations')
apis_dir = File.join(home, 'oas_db', 'apis')
exp_dir = File.join(home, 'oas_db_restler_experiment')

puts "OAS DB: #{Time.now}"

samples = Dir.children(samples_dir).map { |f| File.join(samples_dir, f) }
samples.each do |sample|
  basename = File.basename(sample, '.*')
  exp_instance_dir = File.join(exp_dir, basename)

  ['samples', 'annotations', 'apis', 'sinatra_logs'].each do |d|
    FileUtils.mkdir_p(File.join(exp_instance_dir, d))
  end

  sinatra_logs_path = File.join(exp_instance_dir, 'sinatra_logs', 'log.txt')
  FileUtils.touch(sinatra_logs_path)

  [
    [File.join(samples_dir, "#{basename}.json"), 'samples'],
    [File.join(annotations_dir, "#{basename}.json"), 'annotations'],
    [File.join(apis_dir, "#{basename}.rb"), 'apis']
  ].each do |src_dest|
    FileUtils.cp(src_dest.first, File.join(exp_instance_dir, src_dest.last))
  end

  api_spec_path = File.join(exp_instance_dir, 'samples', "#{basename}.json")
  mock_api_path = File.join(exp_instance_dir, 'apis', "#{basename}.rb")

  puts "OAS DB: Starting experiment for #{basename}"

  puts 'OAS DB: Starting mock API server...'
  system("nohup ruby #{mock_api_path} -p 3000 -e production >> #{sinatra_logs_path} 2>&1 &")
  sleep 5 # Gives time to Sinatra to boot up before getting its PID.
  mock_api_pid_txt = %x(cat #{sinatra_logs_path} | grep pid=)
  mock_api_pid = mock_api_pid_txt.match(/pid=(\d+)/)[1] # PID of Sinatra that is now running on the background.

  puts 'OAS DB: Running RESTler in quick mode...'
  FileUtils.cd(restler_quick_start_script_path)
  system("python ./restler-quick-start.py --api_spec_path #{api_spec_path} --restler_drop_dir #{restler_drop_dir}")

  puts 'OAS DB: Running RESTler fuzzer...'
  FileUtils.cd(restler_binary_path)
  # system("./Restler fuzz-lean --no_ssl --grammar_file #{restler_grammar_file} --dictionary_file #{restler_dict_file} --enable_checkers UseAfterFree,PayloadBody,Examples")
  system("./Restler fuzz --no_ssl --grammar_file #{restler_grammar_file} --dictionary_file #{restler_dict_file} --enable_checkers UseAfterFree,PayloadBody,Examples --time_budget 0.25")

  # IMPORTANT: Remember to change results directory depending on the mode you just ran.
  # fuzz_results_dir = File.join(restler_binary_path, 'FuzzLean', 'RestlerResults')
  fuzz_results_dir = File.join(restler_binary_path, 'Fuzz', 'RestlerResults')
  FileUtils.cp_r(fuzz_results_dir, exp_instance_dir)

  puts 'OAS DB: Cleaning up...'
  sigterm = 15
  system("kill -#{sigterm} #{mock_api_pid}")
  FileUtils.rm_r(File.join(home, 'restler-fuzzer', 'restler_working_dir'))
  # FileUtils.rm_r(File.join(restler_binary_path, 'FuzzLean'))
  FileUtils.rm_r(File.join(restler_binary_path, 'Fuzz'))
  puts '------------------------------------------------------------------'
end

puts "OAS DB: #{Time.now}"
