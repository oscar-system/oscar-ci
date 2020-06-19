#!/usr/bin/env ruby
require_relative "../settings.rb"
require "fileutils"

FileUtils.mkdir_p $JUPYTER_BASE

system! "python3", "-m", "venv", $IPYTHON
system! "#{$IPYTHON}/bin/pip", "install", "--cache-dir",
  "#{$JUPYTER_BASE}/.pip-cache", "jupyter", "notebook"

system! "julia", "meta/install/install-jupyter.jl"

jupyter = "#{$IPYTHON}/bin/jupyter"
FileUtils.ln_sf jupyter, "#{$WORKSPACE}/local/bin"
jupyter_data_dir = ENV["JUPYTER_DATA_DIR"]
kernel_json = Dir.glob("#{jupyter_data_dir}/**/julia-*/kernel.json",
  File::FNM_DOTMATCH).first

system "sed", "-i", "-e", "/--project=/d", kernel_json
