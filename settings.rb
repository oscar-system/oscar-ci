$WORKSPACE = ENV["WORKSPACE"]
$JULIA_ENV = "#{$WORKSPACE}/julia-env"
$JUPYTER_BASE = "#{$WORKSPACE}/jupyter"
$IPYTHON = "#{$JUPYTER_BASE}/ipython-env"
ENV.update({
  # This is where Julia packages and project files go, respectively
  "JULIA_DEPOT_PATH" => $JULIA_ENV,
  "JULIA_PROJECT" => $JULIA_ENV,
  # Ensure we use wget for more robust downloads
  "BINARYPROVIDER_DOWNLOAD_ENGINE" => "wget",
  # This is where gap, julia, etc. will be located.
  "PATH" => "#{$WORKSPACE}/local/bin:#{ENV['PATH']}",
  "JUPYTER_BASE" => $JUPYTER_BASE,
  # This is where we store the Jupyter configuration.
  "JUPYTER_CONFIG_DIR" => "#{$JUPYTER_BASE}/jupyterenv/config",
  "JUPYTER_DATA_DIR" => "#{$JUPYTER_BASE}/jupyterenv/data",
  "JUPYTER_RUNTIME_DIR" => "#{$JUPYTER_BASE}/jupyterenv/runtime",
  # Avoid problems with Unicode and terminal codes.
  "LC_ALL" => "C",
  "TERM" => "dumb"
})
