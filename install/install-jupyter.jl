include("../packages.jl")
include("../safepkg.jl")

SafePkg.add("IJulia")
SafePkg.build("IJulia")

for pkg in notebook_packages
  SafePkg.add(pkg)
end
