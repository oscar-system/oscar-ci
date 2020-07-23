#!/usr/bin/env ruby
require_relative "../settings"
require_relative "../utils"

FileUtils.rm_tree $JULIA_ENV
system! "julia", "meta/install/install-oscar.jl"
