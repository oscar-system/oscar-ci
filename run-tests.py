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
    logdir = "logs/build-%s" % buildnum
    os.makedirs(logdir)
    for test in tests:
        testscript = "meta/tests/" + test.script
        logfile = os.path.join(logdir, test.name + ".log")
        def log(s):
            with open(logfile, "ab") as logfp:
                if type(s) == type(u""):
                    s = bytearray(s, "utf-8")
                logfp.write(s)
                if not s.endswith(b"\n"):
                    logfp.write(b"\n")
        try:
            start = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
            log("=== %s (%s) at %s\n" % (test.name, testscript, start))
            cmd = testscript
            cmd += " >>" + logfile + " 2>&1"
            result = subprocess.run(cmd, shell=True, timeout = test.timeout)
            exitcode = result.returncode
            if exitcode == 0:
                verbose_status = "SUCCESS"
            else:
                verbose_status = "FAILURE (status = %d)" % exitcode
        except subprocess.TimeoutExpired as result:
            output = result.stdout
            exitcode = -1
            verbose_status = "TIMEOUT"
        except:
            output = "INTERNAL ERROR\n"
            verbose_status = "INTERNAL ERROR"
            exitcode = -1
        failed_tests = failed_tests or exitcode != 0
        stop = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        log("=== %s at %s\n" % (verbose_status, stop))
        print("Testing: %-19s at %s => %s" % (test.name, start, verbose_status))
        sys.stdout.flush()
    log_url = os.environ["BUILD_URL"]
    if not log_url.endswith("/"):
        log_url += "/"
    log_url += "artifact/logs/build-" + buildnum + "/"
    print("Logs: " + log_url)
    if failed_tests:
        exit(1)

if __name__ == "__main__":
    run_tests()
