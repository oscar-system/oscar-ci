extra_packages = [ "Cxx", "ImplicitPlots", "Plots", "HomotopyContinuation" ]

using Pkg
Pkg.add("IJulia")
Pkg.build("IJulia")

for pkg in extra_packages
  Pkg.add(pkg)
end
