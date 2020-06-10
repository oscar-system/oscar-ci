$OSCAR_CI_NAME = ENV["OSCAR_CI_NAME"] || "oscar-ci"
$OSCAR_CI_IMAGE = ENV["OSCAR_CI_IMAGE"] || $OSCAR_CI_NAME
$JENKINS_HOME = ENV["JENKINS_HOME"] ||
 "#{ENV["HOME"]}/jenkins/#{ENV["OSCAR_CI_NAME"]}"
ENV["JENKINS_HOME"] = $JENKINS_HOME
$JENKINS_WAR = ENV["JENKINS_WAR"] || File.expand_path("#{__dir__}/jenkins.war")