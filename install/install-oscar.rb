#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

FileUtils.rm_rf $JULIA_ENV
system "julia", "meta/install/install-oscar.jl"
