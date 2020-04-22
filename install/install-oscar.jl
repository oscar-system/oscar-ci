using Pkg

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "Oscar"
]

Master(name) = PackageSpec(path=string(name, ".jl"))
Stable(name) = PackageSpec(name=name)
GetPackageSpec(name) = get(ENV, "BUILDTYPE", "master") == "master" ?
  Master(name) : Stable(name)

pkglog = ".pkgerrors"

try
  close(open(pkglog, "w")) # create empty file
catch
  # ignore IO errors
end

function Add(name)
  try
    Pkg.add(GetPackageSpec(name))
  catch err
    msg = replace(replace(replace(err.msg,
      r"├|└" => "+"), r"─" => "-"), r"│" => "|")
    try
      open(pkglog, "a") do fp
	write(fp, string("=== failed to add package ", name, "\n"))
	write(fp, string(msg, "\n"))
      end
    catch
      # ignore IO errors
    end
    for (exception, backtrace) in Base.catch_stack()
      showerror(stdout, exception, backtrace)
      println()
    end
  end
end

for pkg in packages
  Add(pkg)
end

Pkg.update()
