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
    with open("meta/tests/config.yaml") as config:
        return yaml.safe_load(config.read())

def make_job_url(buildnum):
    import os
    url = os.environ["JENKINS_URL"]
    job = os.environ["JOB_NAME"]
    if not url.endswith("/"): url += "/"
    url += "job/%s/%s/" % (job, buildnum)
    return url

class TestRunner:
    def __init__(self):
        # Init instance variables
        import os, threading, concurrent.futures as futures
        self.failed_tests = False
        self.buildnum = os.environ.get("BUILD_NUMBER", "0")
        self.jenkins_home = os.environ["JENKINS_HOME"]
        self.job = os.environ["JOB_NAME"]
        self.build_url = os.environ["BUILD_URL"]
        self.maxjobs = int(os.environ.get("BUILDJOBS", 4))
        if not self.build_url.endswith("/"): self.build_url += "/"
        self.log_url = self.build_url + "artifact/logs/build-" + self.buildnum
        self.logdir = "logs/build-%s" % self.buildnum
        self.start_date = None
        self.end_date = None
        self.successes = []
        self.failures = []
        self.testresults = []
        self.lock = threading.Lock()
        self.threadpool = futures.ThreadPoolExecutor(max_workers=self.maxjobs)
        self.futures = {}
        # Create log dir for this build
        try: os.makedirs(self.logdir, exist_ok=True)
        except: pass
    def report(self, msg, index, exitcode):
        if exitcode == 0:
            self.successes.append((index, msg))
        else:
            self.failures.append((index, msg))
    def _run(self, test, index = 0):
        import os, subprocess, datetime, yaml, re
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
        logfile = os.path.join(self.logdir, testfilename + ".log")
        info["log"] = "%s/%s.log" % (self.log_url, testfilename)
        def log(s):
            with open(logfile, "ab") as logfp:
                if type(s) == type(u""):
                    s = bytearray(s, "utf-8")
                logfp.write(s)
        # Run the test and record its status
        try:
            start_time = datetime.datetime.now()
            with self.lock:
                if self.start_date is None:
                    self.start_date = start_time.strftime("%Y-%m-%d")
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
        with self.lock:
            self.failed_tests = self.failed_tests or exitcode != 0
        info["success"] = (exitcode == 0)
        info["exitcode"] = exitcode
        info["status"] = verbose_status.lower()
        if verbose_status == "FAILURE":
            verbose_status += " (status = %d)" % exitcode
        # Timing information
        stop_time = datetime.datetime.now()
        stop = stop_time.strftime("%Y-%m-%d %H:%M")
        with self.lock:
            new_end_date = stop_time.strftime("%Y-%m-%d")
            if self.end_date is None or new_end_date > self.end_date:
                self.end_date = new_end_date
        duration = (stop_time - start_time).seconds
        info["duration"] = duration
        # Make a persistent record of the last success/first failure
        jobstate_dir = self.jenkins_home + "/jobstate"
        jobstate = mkpath(jobstate_dir, self.job + ".yaml")
        os.makedirs(jobstate_dir, exist_ok=True)
        with self.lock:
            db = YamlDB(jobstate)
            info["last_success"] = False
            info["last_success_url"] = None
            info["first_failure"] = False
            info["first_failure_url"] = None
            if exitcode == 0:
                last_success = ""
                first_failure = ""
                db[testname] = [ self.buildnum, "" ]
            else:
                if testname in db:
                    if db[testname][1] == "":
                        db[testname][1] = self.buildnum
                else:
                    db[testname] = [ "", self.buildnum ]
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
             self.log_url + "/" + testfilename + ".log", start_short,
             "%d seconds" % duration, last_success, first_failure)
        with self.lock:
            self.report(testsummary, index, exitcode)
            self.testresults.append((index, info))
        log("=== %s at %s\n" % (verbose_status, stop))
        return "Testing: %-19s at %s => %s" % (testname, start, verbose_status)
    def run(self, test):
        import sys
        msg = self._run(test)
        print(msg)
        sys.stdout.flush()
    def _start(self, test, index):
        after = test.get("after", None)
        dep = self.futures.get(after, None)
        if after is not None and dep is None:
            print("Warning: Invalid dependency %s => %s" % (test["name"],
                    after))
        else:
            if dep is not None:
                self.futures[after].result()
        return self._run(test, index)
    def start(self, test, index=0):
        with self.lock:
            future = self.threadpool.submit(self._start, test, index)
            self.futures[test["name"]] = future
            return future
    def finish(self):
        import yaml
        def reindex(l):
            l.sort()
            l[:] = [ item for index, item in l ]
        print("Logs: " + self.log_url + "/")
        # Print a human readable report
        report_form = ""
        report_form += "## [Build %s](%s)\n\n" % (self.buildnum, self.build_url)
        report_form += "* Started on: %s\n" % self.start_date
        report_form += "* Ended on: %s\n\n" % self.end_date
        report_form += \
            "| Test Name    | Result | Start | Duration | Last Success | First Failure |\n" + \
            "|:-------------|:-------|:------|:---------|:-------------|:--------------|\n"
        reindex(self.failures)
        reindex(self.successes)
        reindex(self.testresults)
        if len(self.failures) > 0:
            report_form += "\n".join(self.failures)
            report_form += "\n"
        if len(self.successes) > 0:
            report_form += "\n".join(self.successes)
            report_form += "\n"
        # Dump report into a yaml file
        upload(self.job, self.buildnum, {
            "README.md" : report_form,
            "_data/ci.yml" : yaml.dump({
                "build": int(self.buildnum),
                "build_url": self.build_url,
                "job": self.job,
                "tests": self.testresults
            }, default_flow_style=False)
        })

def run_tests(tests):
    import sys
    testrunner = TestRunner()
    tasks = [ testrunner.start(test, index)
        for index, test in zip(range(len(tests)), tests) ]
    for task in tasks:
        print(task.result())
        sys.stdout.flush()
    testrunner.finish()
    if testrunner.failed_tests:
        exit(1)

if __name__ == "__main__":
    tests = load_config()
    run_tests(tests)
