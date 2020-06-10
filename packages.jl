using Pkg

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "GroupAtlas",
  "GroebnerBasis", "Oscar"
]

locations = Dict(
  "GroupAtlas" => PackageSpec(path="GroupAtlas.jl")
)

notebook_packages = [
  "ImplicitPlots", "Plots", "HomotopyContinuation",
  PackageSpec(path="notebooks-gitfans")
]
