require 'fileutils'
require 'active_support/all'

# IMPORTANT:
# Insert the absolute path of oas_db as the value of home.
# Insert the absolute path of the RESTest project as the value of restest_home.
home = '/Users/alexbrahastoll/Projects/mestrado/oas_db'
restest_home = '/Users/alexbrahastoll/Projects/mestrado/RESTest'
restest_exp_home = File.join(home, 'restest_experiment')

restest_binary_path = File.join(restest_home, 'restest.jar')
samples_dir = File.join(home, 'samples')
annotations_dir = File.join(home, 'annotations')
apis_dir = File.join(home, 'apis')
now = Time.now
exp_dir = File.join(home, 'restest_experiment', "experiment_run_#{now.to_i}")

puts "OAS DB: #{Time.now}"

samples = Dir.children(samples_dir).keep_if { |f| f.end_with?('.json') }.map { |f| File.join(samples_dir, f) }
samples.each do |sample|
  basename = File.basename(sample, '.*')
  exp_instance_dir = File.join(exp_dir, basename)

  ['samples', 'annotations', 'apis', 'restest_conf', 'restest_tests', 'sinatra_logs', 'restest_logs'].each do |d|
    FileUtils.mkdir_p(File.join(exp_instance_dir, d))
  end

  sinatra_logs_path = File.join(exp_instance_dir, 'sinatra_logs', 'log.txt')
  restest_logs_path = File.join(exp_instance_dir, 'restest_logs', 'log.txt')
  FileUtils.touch(sinatra_logs_path)
  FileUtils.touch(restest_logs_path)

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

  puts 'OAS DB: Generating RESTest properties file...'
  properties_file_contents = <<~RESTEST
    # ADD HERE ANY EXTRA INFORMATION TO BE DISPLAY IN THE TEST REPORT

    # API name
    api=#{basename.classify}

    # CONFIGURATION PARAMETERS

    # Test case generator
    generator=FT

    # Number of test cases to be generated per operation on each iteration
    testsperoperation=4

    # OAS specification
    oas.path=#{api_spec_path}

    # Directory where the test cases will be generated
    test.target.dir=#{File.join(exp_instance_dir, 'restest_tests')}

    # Package name
    test.target.package=#{'oasdb.' + basename.gsub('_', '')}

    # Experiment name (for naming related folders and files)
    experiment.name=#{basename.classify}

    # Name of the test class to be generated
    testclass.name=#{('oas_db_' + basename).classify}

    # Measure input coverage
    coverage.input=true

    # Measure output coverage
    coverage.output=true

    # Enable CSV statistics
    stats.csv=false

    # Maximum number of test cases to be generated
    numtotaltestcases=224

    # Optional delay between each iteration (in seconds)
    delay=-1

    # Ratio of faulty test cases to be generated (negative testing)
    faulty.ratio=0.5

  RESTEST
  restest_properties_path = File.join(exp_instance_dir, 'restest_conf', 'restest.properties')
  File.write(restest_properties_path, properties_file_contents)

  puts 'OAS DB: Running RESTest in FT mode (fuzzer)...'
  # Probably a RESTest bug, but even when using the JAR we must have the complete RESTest project
  # in the local disk and run the jar from within the project directory
  FileUtils.cd(restest_home)
  system("java -jar restest.jar #{restest_properties_path} >> #{restest_logs_path} 2>&1")
  FileUtils.cd(restest_exp_home)

  results_dir = File.join(restest_home, 'target')
  FileUtils.cp_r(results_dir, exp_instance_dir)
  FileUtils.mv(File.join(exp_instance_dir, 'target'), File.join(exp_instance_dir, 'restest_results'))

  puts 'OAS DB: Cleaning up...'
  sigterm = 15
  system("kill -#{sigterm} #{mock_api_pid}")
  FileUtils.rm_r(results_dir)
  puts '------------------------------------------------------------------'
end

puts "OAS DB: #{Time.now}"
