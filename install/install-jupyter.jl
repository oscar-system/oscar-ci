using Pkg

include("../packages.jl")

function SafeAdd(name)
  try
    Pkg.add(name)
  catch
    for (exception, backtrace) in Base.catch_stack()
      showerror(stdout, exception, backtrace)
      println()
    end
  end
end

Pkg.add("IJulia")
Pkg.build("IJulia")

for pkg in notebook_packages
  SafeAdd(pkg)
end
