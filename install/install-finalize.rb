#!/usr/bin/env ruby
require_relative "../settings.rb"
safepkg = File.expand_path("#{__dir__}/../safepkg.jl")
system! %Q{julia -e 'include("#{safepkg}"); SafePkg.precompile()'}
