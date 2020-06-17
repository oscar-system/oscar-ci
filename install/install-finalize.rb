#!/usr/bin/env ruby
require_relative "../settings.rb"
system %q{julia -e 'include("meta/safepkg.jl"); SafePkg.precompile()'} or exit 1
