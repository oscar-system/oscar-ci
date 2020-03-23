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

def repo_url(job):
    info = credentials[job]
    if info is None:
        return None
    user = info["user"]
    token = info["token"]
    repo = info["repo"]
    url = "https://%s:%s@github.com/%s" % (user, token, repo)
    return url

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
    return subprocess.run(cmd, stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL)

def clone(job):
    import os, shutil
    if job in credentials:
        if os.path.exists("report"):
            return
        shutil.rmtree("report.tmp", ignore_errors=True)
        git("!clone", repo_url(job), "report.tmp")
        git("-C", "report.tmp", "config",
            "--local", "user.email", "oscar@computeralgebra.de")
        git("-C", "report.tmp", "config",
            "--local", "user.name", "OSCAR Automation")
        git("-C", "report.tmp", "reset", "--hard", "master")
        shutil.move("report.tmp", "report")

def push(job):
    if job in credentials:
        git("push", repo_url(job), "-f", "master")

def add_file(path, contents):
    with open(mkpath("report", path), "w") as outfile:
        outfile.write(contents)
    git("add", path)

def commit(msg):
    git("commit", "-m", msg)

def upload(job, build, files):
    read_credentials()
    if job not in credentials:
        return
    clone(job)
    for path, contents in files.items():
        add_file(path, contents)
    commit("Build " + str(build))
    push(job)

# Test runner

default_timeout = 1800

class FileLock:
    def __init__(self, path):
        self.path = path + ".lock"
    def __enter__(self):
        import fcntl
        self.file = open(self.path, "w+")
        fcntl.lockf(self.file, fcntl.LOCK_EX)
    def __exit__(self, *args):
        import fcntl
        fcntl.lockf(self.file, fcntl.LOCK_UN)
        self.file.close()

def load_config():
    import yaml
    global tests
    with open("meta/tests/config.yaml") as config:
        tests = yaml.safe_load(config.read())

def run_tests():
    import sys, os, subprocess, datetime, shelve
    failed_tests = False
    buildnum = os.environ.get("BUILD_NUMBER", "0")
    # Create log dir if it does not exist yet
    try: os.mkdir("logs")
    except: pass
    # Output files
    logdir = "logs/build-%s" % buildnum
    build_url = os.environ["BUILD_URL"]
    job = os.environ["JOB_NAME"]
    jenkins_home = os.environ["JENKINS_HOME"]
    if not build_url.endswith("/"):
        build_url += "/"
    log_url = build_url + "artifact/logs/build-" + buildnum
    proj_url = build_url + "jenv/proj"
    try: os.mkdir(logdir)
    except: pass
    successes = []
    failures = []
    def report(s, exitcode):
        if exitcode == 0:
            successes.append(s)
        else:
            failures.append(s)
    for test in tests:
        testscript = "meta/tests/" + test["script"]
        testname = test["name"]
        if "timeout" in test:
            timeout = test["timeout"]
        else:
            timeout = default_timeout
        logfile = os.path.join(logdir, testname + ".log")
        def log(s):
            with open(logfile, "ab") as logfp:
                if type(s) == type(u""):
                    s = bytearray(s, "utf-8")
                logfp.write(s)
        try:
            start_time = datetime.datetime.now()
            start = start_time.strftime("%Y-%m-%d %H:%M")
            log("=== %s (%s) at %s\n" % (testname, testscript, start))
            cmd = testscript
            cmd += " >>" + logfile + " 2>&1"
            result = subprocess.run(cmd, shell=True, timeout = timeout)
            exitcode = result.returncode
            if exitcode == 0:
                verbose_status = "SUCCESS"
                statuscode = "\u2705"
            else:
                verbose_status = "FAILURE (status = %d)" % exitcode
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
        jobstate_dir = jenkins_home + "/jobstate"
        jobstate = mkpath(jobstate_dir, job)
        os.makedirs(jobstate_dir, exist_ok=True)
        with FileLock(jobstate):
            if exitcode == 0:
                last_success = ""
                with shelve.open(jobstate) as db:
                    db[testname] = (buildnum, build_url)
            else:
                with shelve.open(jobstate) as db:
                    if testname in db:
                        last_success = "[%s](%s)" % db[testname]
                    else:
                        last_success = "unknown"
        failed_tests = failed_tests or exitcode != 0
        stop_time = datetime.datetime.now()
        stop = stop_time.strftime("%Y-%m-%d %H:%M")
        duration = (stop_time - start_time).seconds
        testsummary = "| %s | %s [%s](%s) | %s | %s | %s |" % \
            (testname, statuscode, verbose_status,
             log_url + "/" + testname + ".log", start, "%d seconds" % duration,
             last_success)
        report(testsummary, exitcode)
        log("=== %s at %s\n" % (verbose_status, stop))
        print("Testing: %-19s at %s => %s" % (testname, start, verbose_status))
        sys.stdout.flush()
    print("Logs: " + log_url + "/")
    report_form = ""
    report_form += "## [Build %s](%s)\n\n" % (buildnum, build_url)
    report_form += \
        "| Test Name    | Result | Start | Duration | Last Success |\n" + \
        "|:-------------|:-------|:------|:---------|:-------------|\n"
    if len(failures) > 0:
        report_form += "\n".join(failures)
        report_form += "\n"
    if len(successes) > 0:
        report_form += "\n".join(successes)
        report_form += "\n"
    upload(job, buildnum, { "README.md" : report_form })
    if failed_tests:
        exit(1)

if __name__ == "__main__":
    load_config()
    run_tests()
