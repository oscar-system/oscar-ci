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

from collections import namedtuple

default_timeout = 1800

TestRecord = namedtuple("Test", ["name", "script", "timeout"])

def Test(name, script=None, timeout=default_timeout):
    if not script:
        # make name lower case and strip all non alpha-numeric characters
        sname = "".join([ ch for ch in name.lower() if ch.isalnum() ])
        script = "test-%s.sh" % sname
    return TestRecord(name, script, timeout)

with open("meta/tests/config.py") as config:
    tests = eval(config.read(), globals(), locals())

def run_tests():
    import sys, os, subprocess, datetime
    failed_tests = False
    buildnum = os.environ.get("BUILD_NUMBER", "0")
    # Create log dir if it does not exist yet
    try: os.mkdir("logs")
    except: pass
    # Output files
    logdir = "logs/build-%s" % buildnum
    log_url = os.environ["BUILD_URL"]
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
        testscript = "meta/tests/" + test.script
        logfile = os.path.join(logdir, test.name + ".log")
        def log(s):
            with open(logfile, "ab") as logfp:
                if type(s) == type(u""):
                    s = bytearray(s, "utf-8")
                logfp.write(s)
        try:
            start_time = datetime.datetime.now()
            start = start_time.strftime("%Y-%m-%d %H:%M")
            log("=== %s (%s) at %s\n" % (test.name, testscript, start))
            cmd = testscript
            cmd += " >>" + logfile + " 2>&1"
            result = subprocess.run(cmd, shell=True, timeout = test.timeout)
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
        failed_tests = failed_tests or exitcode != 0
        stop_time = datetime.datetime.now()
        stop = stop_time.strftime("%Y-%m-%d %H:%M")
        duration = (stop_time - start_time).seconds
        testsummary = "| %s | %s [%s](%s.log) | %s | %s |" % \
            (test.name, statuscode, verbose_status,
             log_url + "artifact/logs/build-" + buildnum + "/" + test.name,
             start, "%d seconds" % duration)
        report(testsummary, exitcode)
        log("=== %s at %s\n" % (verbose_status, stop))
        print("Testing: %-19s at %s => %s" % (test.name, start, verbose_status))
        sys.stdout.flush()
    if not log_url.endswith("/"):
        log_url += "/"
    log_url += "artifact/logs/build-" + buildnum + "/"
    print("Logs: " + log_url)
    job = os.environ["JOB_NAME"]
    report_form = ""
    if len(failures) > 0:
        report_form += \
            "| Failed Tests | Result | Start | Duration |\n" + \
            "|--------------|--------|-------|----------|\n"
        report_form += "\n".join(failures)
        report_form += "\n\n"
    if len(successes) > 0:
        report_form += \
            "| Successful Tests | Result | Start | Duration |\n" + \
            "|------------------|--------|-------|----------|\n"
        report_form += "\n".join(successes)
        report_form += "\n\n"
    upload(job, buildnum, { "README.md" : report_form })
    if failed_tests:
        exit(1)

if __name__ == "__main__":
    run_tests()
