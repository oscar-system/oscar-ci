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
    logfile = "logs/build-%s.log" % buildnum
    for test in tests:
        testscript = "meta/tests/" + test.script
        try:
            start = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
            result = subprocess.run([testscript],
                stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                timeout = test.timeout)
            output = result.stdout
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
        print("Testing: %-19s at %s => %s" % (test.name, start, verbose_status))
        try:
            with open(logfile, "ab") as logfp:
                def log(s):
                    if type(s) == type(u""):
                        s = bytearray(s, "utf-8")
                    logfp.write(s)
                    if not s.endswith(b"\n"):
                        logfp.write(b"\n")
                log("=== %s (%s) at %s\n" % (test.name, testscript, start))
                log(output)
                log("=== %s at %s\n" % (verbose_status, stop))
        except:
            print("INTERNAL ERROR: cannot write test output to logfile.")
        sys.stdout.flush()
    if failed_tests:
        exit(1)

if __name__ == "__main__":
    run_tests()
