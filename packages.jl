using Pkg

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "GroupAtlas", "Oscar"
]

locations = Dict(
  "GroupAtlas" => PackageSpec(path="GroupAtlas.jl")
)

notebook_packages = [
  "Cxx", "ImplicitPlots", "Plots", "HomotopyContinuation",
  PackageSpec(path="notebooks-gitfans")
]
