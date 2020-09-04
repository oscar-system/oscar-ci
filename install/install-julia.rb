#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

if not (ENV["JULIA_VERSION"] || "").start_with?("download:") then
  system! "make -C julia -j#{ENV['BUILDJOBS'] || 4}"
end
for binary in [ "julia/julia", "julia/bin/julia"] do
  path = "#{$WORKSPACE}/#{binary}"
  if File.exist? path then
    FileUtils.ln_sf path, "local/bin" or exit 1
  end
end
