using Pkg

packages = [
  "GAP", "AbstractAlgebra", "Nemo", "Hecke", "LoadFlint",
  "Singular", "Polymake", "HomalgProject", "Oscar"
]

build_type = get(ENV, "BUILDTYPE", "master")

Master(name) = PackageSpec(path=string(name, ".jl"))
Stable(name) = PackageSpec(name=name)
GetPackageSpec(name) = build_type == "master" ? Master(name) : Stable(name)

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

if build_type != "user"
  packages = toposort(dep_graph(packages))
end

pkglog = ".pkgerrors"

try
  close(open(pkglog, "w")) # create empty file
catch
  # ignore IO errors
end

function Add(name)
  try
    Pkg.add(GetPackageSpec(name))
  catch err
    msg = replace(replace(replace(err.msg,
      r"├|└" => "+"), r"─" => "-"), r"│" => "|")
    try
      open(pkglog, "a") do fp
	write(fp, string("=== failed to add package ", name, "\n"))
	write(fp, string(msg, "\n"))
      end
    catch
      # ignore IO errors
    end
    for (exception, backtrace) in Base.catch_stack()
      showerror(stdout, exception, backtrace)
      println()
    end
  end
end

if build_type == "user"
  Add("Oscar")
else
  for pkg in packages
    Add(pkg)
  end
end
