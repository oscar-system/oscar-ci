#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

FileUtils.ln_sf %x{julia meta/gappath.jl}.chomp, "local/bin/gap" or exit 1
