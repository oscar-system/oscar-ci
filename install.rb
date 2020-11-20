#!/usr/bin/env ruby
require_relative "settings.rb"

parts = [ "julia", "oscar", "jupyter", "gap", "gap-packages", "finalize" ]

system! "#{__dir__}/prepare.rb"
for part in parts do
  system! "#{__dir__}/install/install-#{part}.rb"
end
