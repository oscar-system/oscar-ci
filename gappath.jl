devnull = open("/dev/null", "w")
oldstdout = stdout
redirect_stdout(devnull)
using GAP
redirect_stdout(oldstdout)
print(normpath(joinpath(dirname(pathof(GAP)), "..")))
