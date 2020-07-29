#!/usr/bin/env ruby
require_relative "settings.rb"
require "json"

encoding = "en_US.UTF-8"
env = { "LC_ALL" => encoding, "LC_CTYPE" => encoding, "LANGUAGE" => encoding }
notebook = ARGV.shift
basename = File.basename(notebook)
kernel = nil
kernelspecs = JSON.load(%x{jupyter kernelspec list --json})["kernelspecs"]
for name in kernelspecs.keys do
  if name.start_with?("julia-") then
    kernel = name
    break
  end
end
if not kernel then
  puts "=== Error: no Julia Jupyter kernel found"
  exit 1
end

success = system env, "jupyter", "nbconvert",
  "--ExecutePreprocessor.kernel_name=#{kernel}",
  "--ExecutePreprocessor.timeout=600",
  "--to=notebook",
  "--output-dir=#{$WORKSPACE}/notebooks-out",
  "--execute",
  notebook

puts "=== notebook diff for #{basename}"
system env, "meta/nb-diff", "-w", notebook, "notebooks-out/#{basename}"

exit success
