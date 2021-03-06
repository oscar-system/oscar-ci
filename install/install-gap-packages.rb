#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

packages = [ "NemoLinearAlgebraForCAP" ]
pkgdir = %x{julia #{__dir__}/../gappkgpath.jl}.chomp

for pkg in packages do
  FileUtils.rm_f "#{pkgdir}/#{pkg}"
  FileUtils.ln_sf "#{$WORKSPACE}/#{pkg}", pkgdir or exit 1
end
