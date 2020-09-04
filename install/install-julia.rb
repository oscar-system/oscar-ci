#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

if not (ENV["JULIA_VERSION"] || "").start_with?("download:") then
  system! "make -C julia -j#{ENV['BUILDJOBS'] || 4}"
end
FileUtils.ln_sf "#{$WORKSPACE}/julia/bin/julia", "local/bin" or exit 1
