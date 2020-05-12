using Pkg
extra_packages = [
  "Cxx", "ImplicitPlots", "Plots", "HomotopyContinuation",
  PackageSpec(path="notebooks-gitfans")
]

Pkg.add("IJulia")
Pkg.build("IJulia")

for pkg in extra_packages
  Pkg.add(pkg)
end
