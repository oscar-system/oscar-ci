#!/usr/bin/env ruby
require_relative "settings.rb"
require_relative "utils.rb"
require "etc"

version = ARGV.first
major_version = version.split(".")[0..1].join(".")
arch = Etc.uname[:machine]
archdir = if arch == "x86_64" then "x64" else arch end
url = "https://julialang-s3.julialang.org/bin/linux/#{archdir}/#{major_version}/julia-#{version}-linux-#{arch}.tar.gz"


Dir.chdir($WORKSPACE) do
  system! "wget", "-t", "5", "-N", "--no-if-modified-since", url
  FileUtils.rm_tree "julia"
  FileUtils.mkdir_p "julia"
  julia_tar_gz = File.basename(url)
  Dir.chdir("julia") do
    system! "tar", "xzf", "../#{julia_tar_gz}", "--strip-components=1"
  end
end
