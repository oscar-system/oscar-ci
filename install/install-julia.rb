#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

if not ($OscarConfig["julia"] || "").start_with?("download:") then
  system! "make -C #{$WORKSPACE}/julia -j#{$OscarConfig["jobs"] || 4}"
end
for binary in [ "julia/julia", "julia/bin/julia"] do
  path = "#{$WORKSPACE}/#{binary}"
  if File.exist? path then
    FileUtils.ln_sf path, "#{$WORKSPACE}/local/bin" or exit 1
  end
end
