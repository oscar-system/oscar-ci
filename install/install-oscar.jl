using Pkg

include("../packages.jl")
include("../safepkg.jl")

# BUILDTYPE has three possible settings: develop, master, and stable
#
# The master and develop builds will use master branch versions.
#
# The stable build will instead use published versions where available.
#
# For master and stable builds, packages will be added before their
# dependencies. For develop builds, packages will be added after their
# dependencies. The latter makes sure that for each package the newest
# version is tested, but can result in subsequent packages not being
# added due to requirements failures.

build_type = get(ENV, "BUILDTYPE", "master")

SafePkg.set_mode(build_type == "stable" ? SafePkg.stable : SafePkg.master)

# Topological sort of dependencies.
# Any cycles are appended to the graph "as is".

function toposort(graph::Dict{T, Set{T}}; topdown = false)::Vector{T} where T
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
  return topdown ? out : reverse(out)
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

packages = toposort(dep_graph(packages); topdown = build_type != "develop")

# Create an empty log to record errors.
# This is used by the CheckPackages test during the test stage
# to display dependency errors.

try
  close(open(SafePkg.pkglog, "w"))
catch
  # ignore IO errors
end

if build_type != "develop"
  SafePkg.add_smart("Oscar")
  for pkg in packages
    if pkg != "Oscar"
      SafePkg.add_smart(pkg)
    end
  end
else
  for pkg in packages
    SafePkg.add_smart(pkg)
  end
end
