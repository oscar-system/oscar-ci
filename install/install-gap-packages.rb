#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

packages = [ "NemoLinearAlgebraForCAP" ]
pkgdir = %x{julia meta/gappkgpath.jl}.chomp

for pkg in packages do
  FileUtils.rm_f "#{pkgdir}/#{pkg}"
  FileUtils.ln_sf File.realpath(pkg), pkgdir
end
