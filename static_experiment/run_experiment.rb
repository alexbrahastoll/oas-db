require 'fileutils'
require 'json'

puts "OAS DB: #{Time.now}"
puts 'Generating Oasis batch file...'

samples_dir = File.join(Dir.pwd, 'samples')
annotations_dir = File.join(Dir.pwd, 'annotations')
oasis_batch_config = {
  open_api_specs: []
}

samples = Dir.children(samples_dir).
  map { |f| File.join(samples_dir, f) }.
  reject { |f| File.basename(f).start_with?('.') }
samples.each do |sample|
  basename = File.basename(sample, '.*')
  oasis_batch_config[:open_api_specs] << {
    tag: basename,
    path: sample,
    annotation_path: File.join(annotations_dir, basename) + '.json'
  }
end

File.write('static_experiment/oasis_batch.json', JSON.generate(oasis_batch_config))

puts 'Done!'
