include("packages.jl")

failed = []

for package in packages
  try
    eval(Meta.parse(string("using ", package)))
  catch e
    append!(failed, [ package ])
  end
end

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
