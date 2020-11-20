#!/usr/bin/env ruby
require_relative "settings.rb"
require "fileutils"
FileUtils.mkdir_p "#{$WORKSPACE}/local/bin"
package_file = File.expand_path($OscarConfig["packages"],
  File.dirname($OscarConfigPath))
package_config = File.read(package_file)
package_config = ERB.new(package_config, nil, "%").result
package_info = YAML.safe_load(package_config)

def gen_packages_jl(info)
  out = "using Pkg\n\n"
  out << "packages = [\n"
  locations = {}
  for pkg in info["packages"] do
    out << %Q{  "#{pkg["name"]}",\n}
    if pkg["url"] then
      locations[pkg["name"]] = [ pkg["url"], pkg["branch"] ]
    end
  end
  out << "]\n\n"
  out << "notebook_packages = [\n"
  for pkg in info["extra"] do
    out << %Q{  "#{pkg}",\n}
  end
  out << "]\n\n"
  out << "locations = Dict(\n"
  for name, loc in locations do
    url, branch = loc
    if branch then
      spec = %Q{PackageSpec(name="#{name}", url="#{url}", rev="#{branch}")}
    else
      spec = %Q{PackageSpec(name="#{name}", url="#{url}")}
    end
    out << %Q{  "#{name}" => #{spec}\n}
  end
  out << ")\n"
  File.write("#{__dir__}/packages.jl", out)
end

def gen_jenkins_include(info)
  out = ""
  for download in info["downloads"] do
    out << %Q{  get url: "#{download["url"]}"\n}
    if download["branch"] then
      out << %Q{, branch: "#{download["branch"]}"}
    end
    if download["dir"] then
      out << %Q{, dir: "#{download["dir"]}"}
    end
    out << "\n"
  end
  for pkg in info["packages"] do
    url = pkg["url"] || ("https://github.com/" + pkg["github"])
    out << %Q{get url: "#{url}"\n}
  end
end

def do_downloads(info)
  case $OscarConfig["julia"]
  when /^download:(.*)/ then
    system! "#{__dir__}/download-julia.rb", $1
  when /^tag:(.*)/ then
    system! "git", "clone", "https://github.com/julialang/julia",
      "#{$WORKSPACE}/julia"
    system! "git", "-C", "#{$WORKSPACE}/julia", "checkout", $1
  else
    system! "git", "clone", "--depth", "1", "-b", $OscarConfig["julia"],
      "https://github.com/julialang/julia", "#{$WORKSPACE}/julia"
  end
  for download in info["downloads"] do
    cmd = [ "git", "clone", "--depth", "1" ]
    cmd << download["url"]
    if download["branch"] then
      cmd.push("-b", download["branch"])
    else
      cmd.push("-b", "master")
    end
    if download["dir"] then
      cmd << "#{$WORKSPACE}/#{download["dir"]}"
    else
      cmd << "#{$WORKSPACE}/#{File.basename(download["url"])}"
    end
    system! *cmd
  end
  for pkg in info["packages"] do
    # Do not download repos that are already local
    next if pkg["url"].to_s.start_with?("/")
    cmd = [ "git", "clone", "--depth", "1" ]
    if pkg["github"] then
      cmd << "https://github.com/" + pkg["github"]
      cmd.push("-b", "master")
    else
      cmd << pkg["url"]
      if pkg["branch"] then
        cmd.push("-b", pkg["branch"])
      else
        cmd.push("-b", "master")
      end
    end
    cmd << "#{$WORKSPACE}/#{File.basename(pkg["github"] || pkg["url"])}"
    system! *cmd
  end
end

gen_packages_jl(package_info)
if $OscarConfig["jenkins"] then
  # Let Jenkins handle downloads so we can track commits
  gen_jenkins_include(package_info)
else
  do_downloads(package_info)
end
