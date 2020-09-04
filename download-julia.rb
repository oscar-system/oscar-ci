#!/usr/bin/env ruby
require_relative "settings.rb"
require_relative "utils.rb"

version = ARGV.first
major_version = version.split(".")[0..1].join(".")
url = "https://julialang-s3.julialang.org/bin/linux/x64/#{major_version}/julia-#{version}-linux-x86_64.tar.gz"


Dir.chdir($WORKSPACE) do
  system! "wget", "-q", "-t", "5", "-N", "--no-if-modified-since", url
  FileUtils.rm_tree "julia"
  FileUtils.mkdir_p "julia"
  julia_tar_gz = File.basename(url)
  Dir.chdir("julia") do
    system! "tar", "xzf", "../#{julia_tar_gz}", "--strip-components=1"
  end
end
