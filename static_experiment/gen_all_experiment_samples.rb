configs = Dir.children(File.join(__dir__, 'config')).map { |f| File.join(__dir__, 'config', f) }
configs.each do |config|
  puts "oasdb #{config}"
  system("oasdb #{config}")
end
