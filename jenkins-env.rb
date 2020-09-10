require "yaml"

begin
  extra_env = YAML.safe_load(File.read(File.expand_path("~/.oscar-ci.yaml")))
rescue
  extra_env = {}
end

if extra_env.is_a?(Hash) and extra_env["env"].is_a?(Hash) then
  ENV.update(extra_env["env"] || {})
end

$OSCAR_CI_NAME = ENV["OSCAR_CI_NAME"] || "oscar-ci"
$OSCAR_CI_IMAGE = ENV["OSCAR_CI_IMAGE"] || $OSCAR_CI_NAME
$JENKINS_HOME = ENV["JENKINS_HOME"] ||
 "#{ENV["HOME"]}/jenkins/#{ENV["OSCAR_CI_NAME"]}"
ENV["JENKINS_HOME"] = $JENKINS_HOME
$JENKINS_WAR = ENV["JENKINS_WAR"] || File.expand_path("#{__dir__}/jenkins.war")
