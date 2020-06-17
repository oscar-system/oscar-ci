using Pkg

include("../packages.jl")
include("../safepkg.jl")

# BUILDTYPE has three possible settings: master, stable, and user
#
# The master build will use master branch versions of all packages
# where available.
#
# The stable build will instead use published versions where available.
#
# Both master and stable builds will parse the dependency graph and
# add packages in bottom-up order. This will trigger errors that
# would not show by a simple Pkg.add("Oscar"), which will downgrade
# dependent packages if necessary.
#
# Why do we this? Because a user may have done a Pkg.add("GAP"), say,
# and then runs into problems with Pkg.add("Oscar") later.
#
# The user build will instead simply install Oscar first and then
# all dependent packages. This is the typical process with a clean
# ~/.julia setup.

build_type = get(ENV, "BUILDTYPE", "master")

SafePkg.set_mode(build_type == "master" ? SafePkg.master : SafePkg.stable)

# Topological sort of dependencies.
# Any cycles are appended to the graph "as is".

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

if build_type != "release"
  packages = toposort(dep_graph(packages))
end

# Create an empty log to record errors.
# This is used by the CheckPackages test during the test stage
# to display dependency errors.

pkglog = ".pkgerrors"

try
  close(open(pkglog, "w"))
catch
  # ignore IO errors
end

if build_type == "release"
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
