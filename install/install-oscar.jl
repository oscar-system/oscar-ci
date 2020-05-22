using Pkg

include("../packages.jl")
include("../safepkg.jl")

function toposort(graph::Dict{T, Set{T}})::Vector{T} where T
  graph = copy(graph)
  vertices = keys(graph)
  for (v, e) in graph
    intersect!(graph[v], vertices)
  end
  out = Vector{T}()
  while true
    # find all with no successors
    leaves = Vector{T}()
    for (v, e) in graph
      if isempty(e)
        push!(leaves, v)
      end
    end
    if isempty(leaves)
      break
    end
    append!(out, leaves)
    for v in leaves
      delete!(graph, v)
    end
    for v in keys(graph)
      setdiff!(graph[v], leaves)
    end
  end
  # add any cycles
  append!(out, keys(graph))
  return out
end

function dep_graph(pkgs::Array{String,1})
  graph = Dict{String, Set{String}}()
  for pkg in pkgs
    deps = Set()
    try
      proj = Pkg.TOML.parse(open(f->read(f, String),
          string(pkg, ".jl/Project.toml")))
      deps = Set(keys(proj["compat"]))
    catch; end
    graph[pkg] = deps
  end
  return graph
end

# Unless we're going for an end user build, we're adding the
# packages in order of their dependencies to see if anything
# breaks if we have the newest packages.

if SafePkg.build_type != "user"
  packages = toposort(dep_graph(packages))
end

pkglog = ".pkgerrors"

try
  close(open(pkglog, "w")) # create empty file
catch
  # ignore IO errors
end

if SafePkg.build_type == "user"
  SafePkg.add_smart("Oscar")
else
  for pkg in packages
    SafePkg.add_smart(pkg)
  end
end
