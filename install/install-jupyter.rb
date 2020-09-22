#!/usr/bin/env ruby
require_relative "../settings"
require_relative "../utils"

FileUtils.rm_tree $JUPYTER_BASE
FileUtils.mkdir_p $JUPYTER_BASE

virtualenv_url = "https://bootstrap.pypa.io/virtualenv.pyz"

Dir.chdir($WORKSPACE) do
  system! *%w{wget -t 5 -N --no-if-modified-since}, virtualenv_url
  system! "python3", File.basename(virtualenv_url), $IPYTHON
end
system! "#{$IPYTHON}/bin/pip", "install", "--cache-dir",
  "#{$JUPYTER_BASE}/.pip-cache", "jupyter", "notebook"

system! *%w{julia meta/install/install-jupyter.jl}

jupyter = "#{$IPYTHON}/bin/jupyter"
FileUtils.ln_sf jupyter, "#{$WORKSPACE}/local/bin"
jupyter_data_dir = ENV["JUPYTER_DATA_DIR"]
kernel_json = Dir.glob("#{jupyter_data_dir}/**/julia-*/kernel.json",
  File::FNM_DOTMATCH).first

system *%w{sed -i -e /--project=/d}, kernel_json
