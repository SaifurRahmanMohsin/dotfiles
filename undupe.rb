require 'open3'
require 'fileutils'

if ARGV[0].nil?
  puts "This script requires a directory to operate on"
  exit 1
end

def file_names(path)
  Dir.glob("#{path}/**/*").map do |file|
    file if File.file?(file)
  end.compact.sort
end

def dups?(file_1, file_2)
  return false if (file_1.nil? || file_2.nil?)
  stdin, stdout, stderr = Open3.popen3(%Q|compare -metric RMSE "#{file_1}" "#{file_2}" NULL:|)
  output = stderr.gets
  unless output.include? "error"
    rmse = output.gsub(/ .*\n/, "").to_i
    return rmse < 250
  end
  return false
end

def create_dups_directory(path)
  dups_dir = path + "/dups"
  Dir.mkdir(dups_dir) unless Dir.exists? dups_dir
end

path = ARGV[0]
create_dups_directory(path)
files = file_names(path)

iteration = 0
total_iterations = (files.count * files.count).to_f
files.each do |file_1|
  files.each do |file_2|
    if ((file_1 != file_2) && dups?(file_1, file_2))
      puts "#{file_2} is probably a dup of #{file_1}"
      puts "Moving #{file_2}"
      destination = File.dirname(file_2) + "/dups/" + File.basename(file_2)
      FileUtils.mv(file_2, destination)      
    end
    complete = (iteration += 1 / total_iterations) * 100.00
    printf("%.5f \n", complete)
  end
end
