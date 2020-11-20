require "erb"
require "optparse"
require "shellwords"
require "yaml"

def load_config
  $OscarConfigPath = ENV["OSCAR_CI_CONFIG"]
  OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options]"

    opts.on("--config=CONFIGFILE", "With configuration") do |conf|
      $OscarConfigPath = conf
    end

    opts.on("-h", "--help", "Prints this help") do
      puts opts
      exit
    end
  end.parse!
  if not $OscarConfigPath then
    puts "#{$0}: No config file provided"
    exit 1
  end
  ENV["OSCAR_CI_CONFIG"] = $OscarConfigPath
  config_yaml = File.read($OscarConfigPath)
  config_yaml = ERB.new(config_yaml, nil, "%").result
  $OscarConfig = YAML.safe_load(config_yaml)
end

def expand_config_path(path)
  File.expand_path(path, File.dirname($OscarConfigPath))
end

load_config

$WORKSPACE = File.expand_path($OscarConfig["workspace"])
$JULIA_ENV = $OscarConfig["julia_env"]
$JUPYTER_BASE = File.expand_path($OscarConfig["jupyter"])
$IPYTHON = "#{$JUPYTER_BASE}/ipython-env"
ENV.update({
  # Workspace directory
  "WORKSPACE" => $WORKSPACE,
  "OSCAR_SCRIPT_DIR" => __dir__,
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
def system!(*args, **kw)
  if not system(*args, **kw) then
    puts "Command failed: #{Shellwords.join(args)}"
    exit 1
  end
end
