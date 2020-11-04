#!/usr/bin/env ruby

require "timeout"
require "yaml"
require "yaml/store"
require "open3"

require_relative "settings"
require_relative "utils"

def parse_mem(data)
  case data
  when Integer, nil then
    data
  when /^([0-9]+)$/ then
    $1.to_i
  when /^([0-9]+)[kK]$/ then
    $1.to_i * 1024
  when /^([0-9]+)[mM]$/ then
    $1.to_i * 1024 * 1024
  when /^([0-9]+)[gG]$/ then
    $1.to_i * 1024 * 1024 * 1024
  else
    nil
  end
end

class GitServer
  def initialize(sshbase, httpsbase, credfile)
    @sshbase = sshbase
    @httpsbase = httpsbase
    @credentials = {}
    begin
      @credentials = YAML.safe_load(File.read(credfile))
    rescue
      File.open(".gitlog", "a") do | fp |
        fp.puts(YAML.dump({
          "time" => Time.now.to_s,
          "info" => "missing or unreadable credentials file",
          "file" => credfile
        }))
      end
    end
  end

  def [](job)
    @credentials[job]
  end

  def repo_info(job)
    info = @credentials[job]
    if not info then
      return nil
    end
    repo = info["repo"]
    key = info["key"]
    sshurl = "#{@sshbase}/#{repo}"
    httpsurl = "#{@httpsbase}/#{repo}"
    return repo, key, sshurl, httpsurl
  end
end

class GitRepo

  attr_reader :job, :path, :sshurl, :httpsurl, :key

  def initialize(server, job)
    @server = server
    @env = { }
    @job = job
    @path, @key, @sshurl, @httpsurl = server.repo_info(job)
  end

  def git(*subcmd, autocd: true)
    cmd = [ "git" ]
    if autocd then
      cmd += [ "-C", "report" ]
    end
    cmd += subcmd
    stdout, stderr, status = Open3.capture3(@env, *cmd, stdin_data: "")
    File.open(".gitlog", "a") do | fp |
      fp.puts(YAML.dump({
        "time" => Time.now.to_s,
        "cmd" => cmd.join(" "),
        "stdout" => stdout,
        "stderr" => stderr,
      }))
    end
    return stdout, stderr, status
  end

  def fetch
    if Dir.exist?("report") then
      git("remote", "set-url", "origin", "--", @sshurl)
      git("pull", "--ff-only", "origin", "master")
    else
      FileUtils.rm_tree("report.tmp")
      git("clone", @sshurl, "report.tmp", autocd: false)
      git("-C", "report.tmp", "config",
        "--local", "user.email", "oscar@computeralgebra.de", autocd: false)
      git("-C", "report.tmp", "config",
        "--local", "user.name", "OSCAR Automation", autocd: false)
      git("-C", "report.tmp", "reset", "--hard", "master")
      FileUtils.mv("report.tmp", "report")
    end
  end

  def push
    git("remote", "set-url", "origin", "--", @sshurl)
    git("push", "-f", "origin", "master")
  end

  def add_file(path, contents)
    dir = File.dirname(path)
    if dir != "" then
      dir = "report/#{dir}"
      FileUtils.mkdir_p(dir)
      File.open("report/#{path}", "wb") do | fp |
        fp.write(contents)
      end
    end
    git("add", "--", path)
  end

  def add_tree(path)
    Dir.glob("**/{*,.*}", base: path) do | relpath |
      loc = File.join(path, relpath)
      add_file relpath, File.read(loc) if File.file?(loc)
    end
  end

  def commit(msg)
    git("commit", "-m", msg)
  end

  def upload(job, msg, files: {}, dirs: [])
    return if not @server[job]
    keyfile = File.expand_path("~/.ssh_git_key.#{job}")
    File.write(keyfile, @key)
    FileUtils.chmod(0o600, keyfile)
    @env = {
      "GIT_SSH_COMMAND" => "ssh -o 'StrictHostKeyChecking no' -i #{keyfile}"
    }
    fetch
    dirs.each do | path |
      add_tree(path)
    end
    files.each do | path, contents |
      add_file(path, contents)
    end
    commit(msg)
    push
    FileUtils.rm_f(keyfile)
  end
end

class Logger
  def initialize(path)
    @path = path
    FileUtils.mkdir_p(File.dirname(@path))
  end

  def <<(msg)
    File.open(@path, "a") do | fp |
      fp.write msg
    end
  end
end

class TestRunner

  attr_reader :failed_tests

  DEFAULT_TIMEOUT = 1800

  def initialize(repo, tests)
    @repo = repo
    @tests = tests
    @failed_tests = false
    @buildnum = ENV["BUILD_NUMBER"] || "0"
    @workspace = $WORKSPACE
    @job = repo.job
    @buildurl = strip_trailing_slashes(ENV["BUILD_URL"])
    @artifacturl = "#{@buildurl}/artifact"
    @jenkinsurl = strip_trailing_slashes(ENV["JENKINS_URL"])
    @maxjobs = (ENV["BUILDJOBS"] || 4).to_i
    @logdir = "logs/build-#{@buildnum}"
    @logurlbase = "#{@artifacturl}/#{@logdir}"
    @startdate = nil
    @enddate = nil
    @successes = {}
    @failures = {}
    @testresults = {}
    @jenkinshome = File.expand_path("#{$WORKSPACE}/../..")
    @jobstatepath = "#{@jenkinshome}/jobstate/#{@job}.yaml"
    FileUtils.mkdir_p(File.dirname(@jobstatepath))
    @jobstate = YAML::Store.new(@jobstatepath)
    @lock = Thread::Mutex.new
    @builddir = Dir.pwd
  end

  class Constraints
    def initialize(tests)
      @constraints = {}
      @all = []
      @blocked = false
      for test in tests do
        @all |= test["uses"].to_s.split if test["uses"] != "*"
        @all |= [ test["name"] ]
      end
    end

    private def get_uses(test)
      result = test["uses"].to_s.split + [ test["name"] ]
      result = @all if result.include?("*")
      return result
    end

    def add?(test)
      uses = get_uses(test)
      result = uses.all? { | use | not @constraints[use] }
      if result then
        uses.each { | use | @constraints[use] = true }
      end
      return result
    end

    def remove(test)
      uses = get_uses(test)
      uses.each { | use | @constraints[use] = false }
    end
  end

  private def run_tests_in_parallel
    todo = Thread::Queue.new
    done = Thread::Queue.new
    threads = []
    @maxjobs.times do
      threads << Thread.new(todo, done) do | todo, done |
        loop do
          test = todo.pop
          run_test(test)
          done.push test
        end
      end
    end
    constraints = Constraints.new(@tests)
    complete = 0
    remaining = @tests.dup
    while not remaining.empty? do
      scheduled = false
      for test in remaining do
        if constraints.add?(test) then
          todo.push test
          remaining.delete test
          scheduled = true
          break
        end
      end
      next if scheduled
      last_test = done.pop
      complete += 1
      constraints.remove(last_test)
    end
    while complete < @tests.size do
      done.pop
      complete += 1
    end
    for thread in threads do
      thread.kill
      thread.join
    end
  end

  private def strip_trailing_slashes(url)
    url = url.dup
    while url.end_with?("/") do url.chop! end
    url
  end

  private def report(name, msg, success:)
    if success then
      @successes[name] = msg
    else
      @failures[name] = msg
    end
  end

  private def buildurl
    "#{@buildurl}/"
  end

  private def make_build_url(buildnum)
    "#{@jenkinsurl}/job/#{@job}/#{buildnum}/"
  end

  private def update_jobstate(info, testname, exitcode)
    last_success = first_failure = nil
    @lock.synchronize do
      @jobstate.transaction do
        info["last_success"] = false
        info["last_success_url"] = nil
        info["first_failure"] = false
        info["first_failure_url"] = nil
        if exitcode.zero? then
          last_success = ""
          first_failure = ""
          @jobstate[testname] = [ @buildnum, "" ]
        else
          if @jobstate[testname] then
            if @jobstate[testname][1] == ""
              @jobstate[testname][1] = @buildnum
            end
          else
            @jobstate[testname] = [ "", @buildnum ]
          end
          if @jobstate[testname][0] == "" then
            last_success = "unknown"
            first_failure = "unknown"
          else
            err = @jobstate[testname]
            url = err.map { | n | make_build_url(n.to_s) }
            last_success = "[#{err[0]}](#{url[0]})"
            first_failure = "[#{err[1]}](#{url[1]})"
            info["last_success"] = err[0].to_i
            info["last_success_url"] = url[0]
            info["first_failure"] = err[1].to_i
            info["first_failure_url"] = url[1]
          end
        end
      end
    end
    return last_success, first_failure
  end

  def wspath(path)
    File.expand_path(path, $WORKSPACE)
  end

  private def test_command(test)
    if test["script"] then
      wspath(%Q{meta/tests/#{test["script"]}})
    elsif test["sh"] then
      test["sh"]
    elsif test["julia"] then
      %w{julia -e} + [ test["julia"] ]
    elsif test["package"] then
      %w{julia -e} + [ %Q{import Pkg; Pkg.test("#{test["package"]}")} ]
    elsif test["gap"] then
      %w{gap --quitonbreak -c} + [ test["gap"] ]
    elsif test["gappkg"] then
      gapcode = %Q{Read(Filename(DirectoriesPackageLibrary("#{test["gappkg"]}", "tst"), "testall.g"));}
      %w{gap --quitonbreak -c} + [ gapcode ]
    elsif test["notebook"] then
      [ "ruby", wspath("meta/check-julia-notebook.rb"),
        wspath(test["notebook"]) ]
    else
      fail "invalid test type" # TODO
    end
  end

  private def run_test(test)
    testname = test["name"]
    testfilename = testname.gsub(/[^-._a-zA-Z0-9]+/, "-")
    testid = testname.gsub(/[^a-zA-Z0-9]+/, "-").downcase
    info = { "name" => testname, "id" => testid }
    timeout = test["timeout"] || DEFAULT_TIMEOUT
    logfile = "#{@logdir}/#{testfilename}.log"
    logurl = info["log"] = "#{@logurlbase}/#{testfilename}.log"
    log = Logger.new(logfile)
    begin
      start_time = Time.now
      @lock.synchronize do
        @start_date ||= start_time.strftime("%Y-%m-%d")
      end
      start = start_time.strftime("%Y-%m-%d %H:%M")
      info["start"] = start
      start_short = start_time.strftime("%H:%M")
      log << "=== #{testname} at #{start_short}\n"
      testcmd = test_command(test)
      juliaenv = "#{$WORKSPACE}/julia-env"
      standalone = test["standalone"]
      extra_pkgs = []
      if standalone then
        testdir = "#{$WORKSPACE}/test-env/#{testfilename}"
        FileUtils.rm_tree(testdir)
        FileUtils.mkdir_p(testdir)
        case standalone
        when String then
          extra_pkgs = standalone.split
        when Array then
          extra_pkgs = standalone
        end
      else
        testdir = "."
      end
      polymake_user_dir = "#{$WORKSPACE}/.polymake/#{testfilename}"
      FileUtils.rm_tree(polymake_user_dir)
      FileUtils.mkdir_p(polymake_user_dir)
      testenv = {
        "POLYMAKE_USER_DIR" => polymake_user_dir
      }
      pid = -1
      status = nil
      Timeout.timeout(timeout) do
        proceed = true
        for pkg in extra_pkgs do
          pid = spawn(testenv,
            "julia -e 'import Pkg; Pkg.activate(\".\"); Pkg.add(\"#{pkg}\")'",
            err: [ :child, :out], out: [ logfile, "a"], chdir: testdir)
          _, status = Process.waitpid2(pid)
          if not status.success? then
            proceed = false
            break
          end
        end
        if proceed then
          pid =
            if testcmd.is_a?(String) then
              spawn(testenv, testcmd,
                err: [ :child, :out ], out: [ logfile, "a" ], pgroup: true,
                chdir: testdir)
            else
              spawn(testenv, [ testcmd.first, testcmd.first ], *testcmd[1..-1],
                err: [ :child, :out ], out: [ logfile, "a" ], pgroup: true,
                chdir: testdir)
            end
          _, status = Process.waitpid2(pid)
        end
      end
      exitcode = status.exitstatus
      if exitcode.zero? then
        verbose_status = "SUCCESS"
        statuscode = "\u2705"
      else
        verbose_status = "FAILURE"
        statuscode = "\u274C"
      end
    rescue Timeout::Error
      if pid >= 0 then
        pgid = Process.getpgid(pid)
        Process.kill("TERM", pgid)
        sleep 5
        Process.kill("KILL", pgid)
      end
      exitcode = -1
      verbose_status = "TIMEOUT"
      statuscode = "\u26A0"
    rescue StandardError => ex
      log << "#{ex.backtrace.join("\n")}\n"
      log << "#{ex.inspect}\n"
      exitcode = -1
      verbose_status = "INTERNAL ERROR"
      statuscode = "\u2049"
    end
    @lock.synchronize do
      @failed_tests ||= exitcode != 0
    end
    info["success"] = exitcode.zero?
    info["exitcode"] = exitcode
    info["status"] = verbose_status.downcase
    if verbose_status == "FAILURE" then
      verbose_status += " (status = #{exitcode})"
    end
    stop_time = Time.now
    stop = stop_time.strftime("%Y-%m-%d %H:%M")
    @lock.synchronize do
      new_end_date = stop_time.strftime("%Y-%m-%d")
      @end_date ||= new_end_date
      @end_date = new_end_date if new_end_date > @end_date
    end
    duration = (stop_time - start_time).round
    info["duration"] = duration
    last_success, first_failure = update_jobstate(info, testname, exitcode)
    @testresults[testname] = info
    testsummary =  "| #{testname} "
    testsummary << "| #{statuscode} [#{verbose_status}](#{logurl}) "
    testsummary << "| #{start_short} | #{duration} seconds "
    testsummary << "| #{last_success} | #{first_failure} "
    testsummary << "|"
    @lock.synchronize do
      report(testname, testsummary, success: exitcode.zero?)
    end
    log << "=== #{verbose_status} at #{stop}\n"
    puts format("Testing: %-19<name>s at %<time>s => %<status>s",
      name: testname, time: start, status: verbose_status)
  end

  def ordered(results)
    result = []
    for test in @tests do
      result << results[test["name"]] if results[test["name"]]
    end
    return result
  end

  def finish_report
    successes = ordered(@successes)
    failures = ordered(@failures)
    report = []
    report << "## [Build #{@buildnum}](#{buildurl})\n\n"
    report << "* Started on: #{@start_date}\n"
    report << "* Ended on: #{@end_date}\n\n"
    report << "| Test Name    | Result | Start | Duration | Last Success | First Failure |\n"
    report << "|:-------------|:-------|:------|:---------|:-------------|:--------------|\n"
    report << "#{failures.join("\n")}\n" unless failures.empty?
    report << "#{successes.join("\n")}\n" unless successes.empty?
    @report = report.join
    puts "Logs: #{@logurlbase}"
  end

  def run_all(parallelize:, memlimit: nil)
    if memlimit then
      Process.setrlimit(:DATA, memlimit, memlimit)
    end
    if parallelize > 1 then
      run_tests_in_parallel
    else
      for test in @tests do
        run_test(test)
      end
    end
    finish_report
    if @repo.path then
      @repo.upload(@job, "Build ##{@buildnum}",
        dirs: [
          "meta/layout",
        ],
        files: {
          "README.md" => @report,
          "_data/ci.yml" => YAML.dump({
            "build" => @buildnum.to_i,
            "build_url" => buildurl,
            "job" => @job,
            "organization" => File.dirname(@repo.path),
            "repo" => File.basename(@repo.path),
            "repourl" => @repo.httpsurl,
            "tests" => ordered(@testresults),
          })
        })
    end
  end

end

def get_par_info(parallelize)
  case parallelize
  when nil, false, true then
    parallelize ? (ENV["BUILDJOBS"] || 4).to_i : 0
  when Integer then
    [ parallelize, 0 ].max
  when Hash then
    value = parallelize
    value ||= (ENV["BUILDJOBS"] || 4).to_i
  end
end

def main
  FileUtils.mkdir_p "logs"
  jobname = ENV["JOB_NAME"]
  config = YAML.safe_load(File.read("meta/tests/config.yaml"))
  if config["jobinfo"] then
    config.update(config["jobinfo"][jobname] || {})
  end
  github = GitServer.new("ssh://git@github.com", "https://github.com",
    ENV["CREDENTIALS"] || "/config/credentials.yaml")
  repo = GitRepo.new(github, jobname)
  tests = config["tests"]
  parallelize = get_par_info(config["parallelize"])
  memlimit = parse_mem(config["memlimit"])
  testrunner = TestRunner.new(repo, tests)
  testrunner.run_all(parallelize: parallelize, memlimit: memlimit)
  exit 1 if testrunner.failed_tests
end

main if caller.empty?
