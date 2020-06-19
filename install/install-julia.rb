#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

system! "make -C julia -j#{ENV['BUILDJOBS'] || 4}"
FileUtils.ln_sf "#{$WORKSPACE}/julia/julia", "local/bin" or exit 1
