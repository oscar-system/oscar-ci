using Pkg

# Which packages to add.

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "CapAndHomalg",
  "GroupAtlas", "GroebnerBasis", "Oscar",
]

# The locations dictionary overrides where packages are normally
# to be found.

locations = Dict(
  "LoadFlint" => PackageSpec(name="LoadFlint"),
  "Nemo" => PackageSpec(name="Nemo"),
  "GroupAtlas" => PackageSpec(path="GroupAtlas.jl")
)

# Additional packages needed by notebooks.

notebook_packages = [
  "ImplicitPlots", "Plots", "Distances", "HomotopyContinuation",
  PackageSpec(path="notebooks-gitfans"), "lib4ti2_jll"
]
