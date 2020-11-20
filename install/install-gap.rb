#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

FileUtils.ln_sf %x{julia #{__dir__}/../gappath.jl}.chomp,
  "#{$WORKSPACE}/local/bin/gap" or exit 1
