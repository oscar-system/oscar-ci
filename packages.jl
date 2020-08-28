using Pkg

# Which packages to add.

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "GroupAtlas",
  "GroebnerBasis", "Oscar"
]

# The locations dictionary overrides where packages are normally
# to be found.

locations = Dict(
  "LoadFlint" => PackageSpec(name="LoadFlint"),
  "Nemo" => PackageSpec(name="Nemo"),
  "GroupAtlas" => PackageSpec(path="GroupAtlas.jl"),
  "GAP" => PackageSpec(url="https://github.com/rbehrends/GAP.jl"; rev="test")
)

# Additional packages needed by notebooks.

notebook_packages = [
  "ImplicitPlots", "Plots", "Distances", "HomotopyContinuation",
  PackageSpec(path="notebooks-gitfans"), "lib4ti2_jll"
]
