$WORKSPACE = ENV["WORKSPACE"]
$JULIA_ENV = "#{$WORKSPACE}/julia-env"
$JUPYTER_BASE = "#{$WORKSPACE}/jupyter"
$IPYTHON = "#{$JUPYTER_BASE}/ipython-env"
ENV.update({
  "JULIA_DEPOT_PATH" => $JULIA_ENV,
  "JULIA_PROJECT" => $JULIA_ENV,
  "PATH" => "#{$WORKSPACE}/local/bin:#{ENV['PATH']}",
  "JUPYTER_BASE" => $JUPYTER_BASE,
  "JUPYTER_CONFIG_DIR" => "#{$JUPYTER_BASE}/jupyterenv/config",
  "JUPYTER_DATA_DIR" => "#{$JUPYTER_BASE}/jupyterenv/data",
  "JUPYTER_RUNTIME_DIR" => "#{$JUPYTER_BASE}/jupyterenv/runtime",
  "LC_ALL" => "C",
  "TERM" => "dumb"
})
