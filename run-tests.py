# Uploading reports to GitHub

credentials = { }

def read_credentials():
    import os, yaml
    global credentials
    try:
        path = os.path.expanduser("~/credentials.yaml")
        with open(path) as credsfile:
            creds = yaml.safe_load(credsfile.read())
            if creds:
                credentials = creds
    except:
        pass

def ssh_info(job):
    info = credentials[job]
    if info is None:
        return None
    repo = info["repo"]
    key = info["key"]
    url = "ssh://git@github.com/%s" % repo
    return (url, key)

def mkpath(*args):
    import os
    return os.path.join(*args)

def git(*subcmd):
    import subprocess
    cmd = [ "git" ]
    subcmd = list(subcmd)
    if subcmd[0].startswith("!"):
        subcmd[0] = subcmd[0][1:]
    elif subcmd[0] != "-C":
        cmd.extend(["-C", "report"])
    cmd.extend(subcmd)
    result = subprocess.run(cmd,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    return result

def clone(url):
    import os, shutil
    if os.path.exists("report"):
        git("remote", "set-url", "origin", url)
        git("pull", "--ff-only", "origin", "master")
    else:
        shutil.rmtree("report.tmp", ignore_errors=True)
        git("!clone", url, "report.tmp")
        git("-C", "report.tmp", "config",
            "--local", "user.email", "oscar@computeralgebra.de")
        git("-C", "report.tmp", "config",
            "--local", "user.name", "OSCAR Automation")
        git("-C", "report.tmp", "reset", "--hard", "master")
        shutil.move("report.tmp", "report")

def push(url):
    git("remote", "set-url", "origin", url)
    git("push", "-f", "origin", "master")

def add_file(path, contents):
    import os
    dir = os.path.dirname(path)
    if dir != "":
        os.makedirs(mkpath("report", dir), exist_ok=True)
    with open(mkpath("report", path), "w") as outfile:
        outfile.write(contents)
    git("add", path)

def commit(msg):
    git("commit", "-m", msg)

def upload(job, build, files):
    import os
    read_credentials()
    if job not in credentials:
        return
    url, key = ssh_info(job)
    keyfile = os.path.expanduser("~/.ssh_git_key." + job)
    with open(keyfile, "w") as keyfp:
      keyfp.write(key)
    os.chmod(keyfile, 0o600)
    os.environ["GIT_SSH_COMMAND"] = "ssh -o 'StrictHostKeyChecking no' -i " + keyfile
    clone(url)
    for path, contents in files.items():
        add_file(path, contents)
    commit("Build " + str(build))
    push(url)
    try: os.remove(keyfile)
    except: pass

# Test runner

default_timeout = 1800

class YamlDB(dict):
    def __init__(self, path):
        import yaml, fcntl
        super(YamlDB, self).__init__()
        self.path = path
        self.lock = open("%s.lock" % path, "w+")
        fcntl.lockf(self.lock, fcntl.LOCK_EX)
        try:
            with open(path, "r") as fp:
                self.update(yaml.safe_load(fp))
        except FileNotFoundError:
            pass
    def sync(self):
        import os, yaml
        tmppath = "%s.tmp" % self.path
        data = {}
        data.update(self)
        with open(tmppath, "w") as fp:
            fp.write(yaml.safe_dump(data))
        os.rename(tmppath, self.path)
    def _unlock(self):
        import fcntl
        fcntl.lockf(self.lock, fcntl.LOCK_UN)
        self.lock = None
    def close(self):
        self.sync()
        self._unlock()
    def __del__(self):
        if self.lock is not None:
            self._unlock()

def load_config():
    import yaml
    global tests
    with open("meta/tests/config.yaml") as config:
        tests = yaml.safe_load(config.read())

def make_job_url(buildnum):
    import os
    url = os.environ["JENKINS_URL"]
    job = os.environ["JOB_NAME"]
    if not url.endswith("/"): url += "/"
    url += "job/%s/%s/" % (job, buildnum)
    return url

def run_tests():
    import sys, os, subprocess, datetime, yaml, re
    # Initialize variables
    failed_tests = False
    buildnum = os.environ.get("BUILD_NUMBER", "0")
    jenkins_home = os.environ["JENKINS_HOME"]
    job = os.environ["JOB_NAME"]
    build_url = os.environ["BUILD_URL"]
    if not build_url.endswith("/"): build_url += "/"
    log_url = build_url + "artifact/logs/build-" + buildnum
    proj_url = build_url + "jenv/proj"
    logdir = "logs/build-%s" % buildnum
    start_date = None
    end_date = None
    # Report builder
    successes = []
    failures = []
    testdata = []
    def report(s, exitcode):
        if exitcode == 0:
            successes.append(s)
        else:
            failures.append(s)
    # Create log dir for this build
    try: os.makedirs(logdir, exist_ok=True)
    except: pass
    # Iterate over all tests
    for test in tests:
        # Retrieve information about this test.
        testscript = "meta/tests/" + test["script"]
        testname = test["name"]
        testfilename = re.sub("[^-._a-zA-Z0-9]+", "-", testname)
        info = {}
        info["name"] = testname
        if "timeout" in test:
            timeout = test["timeout"]
        else:
            timeout = default_timeout
        logfile = os.path.join(logdir, testfilename + ".log")
        info["log"] = "%s/%s.log" % (log_url, testfilename)
        def log(s):
            with open(logfile, "ab") as logfp:
                if type(s) == type(u""):
                    s = bytearray(s, "utf-8")
                logfp.write(s)
        # Run the test and record its status
        try:
            start_time = datetime.datetime.now()
            if start_date is None:
                start_date = start_time.strftime("%Y-%m-%d")
            start = start_time.strftime("%Y-%m-%d %H:%M")
            info["start"] = start
            start_short = start_time.strftime("%H:%M")
            log("=== %s (%s) at %s\n" % (testname, testscript, start))
            cmd = testscript
            cmd += " >>" + logfile + " 2>&1"
            result = subprocess.run(cmd, shell=True, timeout = timeout)
            exitcode = result.returncode
            if exitcode == 0:
                verbose_status = "SUCCESS"
                statuscode = "\u2705"
            else:
                verbose_status = "FAILURE"
                statuscode = "\u274C"
        except subprocess.TimeoutExpired as result:
            output = result.stdout
            exitcode = -1
            verbose_status = "TIMEOUT"
            statuscode = "\u26A0"
        except:
            output = "INTERNAL ERROR\n"
            verbose_status = "INTERNAL ERROR"
            statuscode = "\u2049"
            exitcode = -1
        failed_tests = failed_tests or exitcode != 0
        info["success"] = (exitcode == 0)
        info["exitcode"] = exitcode
        info["status"] = verbose_status.lower()
        if verbose_status == "FAILURE":
            verbose_status += " (status = %d)" % exitcode
        # Timing information
        stop_time = datetime.datetime.now()
        stop = stop_time.strftime("%Y-%m-%d %H:%M")
        if end_date is None:
            end_date = stop_time.strftime("%Y-%m-%d")
        duration = (stop_time - start_time).seconds
        info["duration"] = duration
        # Make a persistent record of the last success/first failure
        jobstate_dir = jenkins_home + "/jobstate"
        jobstate = mkpath(jobstate_dir, job + ".yaml")
        os.makedirs(jobstate_dir, exist_ok=True)
        db = YamlDB(jobstate)
        info["last_success"] = False
        info["last_success_url"] = None
        info["first_failure"] = False
        info["first_failure_url"] = None
        if exitcode == 0:
            last_success = ""
            first_failure = ""
            db[testname] = [ buildnum, "" ]
        else:
            if testname in db:
                if db[testname][1] == "":
                    db[testname][1] = buildnum
            else:
                db[testname] = [ "", buildnum ]
            if db[testname][0] == "":
                last_success = "unknown"
                first_failure = "unknown"
            else:
                err = db[testname]
                url = [ make_job_url(str(n)) for n in err ]
                last_success = "[%s](%s)" % (err[0], url[0])
                first_failure = "[%s](%s)" % (err[1], url[1])
                info["last_success"] = int(err[0])
                info["last_success_url"] = url[0]
                info["first_failure"] = int(err[1])
                info["first_failure_url"] = url[1]
        db.close()
        # Log test results
        testsummary = "| %s | %s [%s](%s) | %s | %s | %s | %s |" % \
            (testname, statuscode, verbose_status.lower().capitalize(),
             log_url + "/" + testfilename + ".log", start_short,
             "%d seconds" % duration, last_success, first_failure)
        report(testsummary, exitcode)
        testdata.append(info)
        log("=== %s at %s\n" % (verbose_status, stop))
        print("Testing: %-19s at %s => %s" % (testname, start, verbose_status))
        sys.stdout.flush()
    print("Logs: " + log_url + "/")
    # Print a human readable report
    report_form = ""
    report_form += "## [Build %s](%s)\n\n" % (buildnum, build_url)
    report_form += "* Started on: %s\n" % start_date
    report_form += "* Ended on: %s\n\n" % end_date
    report_form += \
        "| Test Name    | Result | Start | Duration | Last Success | First Failure |\n" + \
        "|:-------------|:-------|:------|:---------|:-------------|:--------------|\n"
    if len(failures) > 0:
        report_form += "\n".join(failures)
        report_form += "\n"
    if len(successes) > 0:
        report_form += "\n".join(successes)
        report_form += "\n"
    # Dump report into a yaml file
    upload(job, buildnum, {
        "README.md" : report_form,
        "_data/ci.yml" : yaml.dump({
            "build": int(buildnum),
            "build_url": build_url,
            "job": job,
            "tests": testdata
        }, default_flow_style=False)
    })
    if failed_tests:
        exit(1)

if __name__ == "__main__":
    load_config()
    run_tests()
