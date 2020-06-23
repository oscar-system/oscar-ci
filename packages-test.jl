using Pkg

include("packages.jl")

failed = []

for package in packages
  try
    eval(Meta.parse(string("module LoadTest$(package) using $(package) end")))
  catch
    append!(failed, [ package ])
    for (exception, backtrace) in Base.catch_stack()
        showerror(stdout, exception, backtrace)
        println()
    end
  end
end


println("=== Package Status")
Pkg.status()
println()
if length(failed) > 0
  println("The following packages failed to load:")
  for package in failed
    println(string("- ", package))
  end
  exit(1)
else
  println("All packages loaded")
  exit(0)
end
