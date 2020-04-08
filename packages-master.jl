using Pkg

function PkgAdd(pkg)
  try
    Pkg.add(pkg)
  catch
    for (exception, backtrace) in Base.catch_stack()
      showerror(stdout, exception, backtrace)
      println()
    end
  end
end

GAP = PackageSpec(path="GAP.jl")
AbstractAlgebra = PackageSpec(path="AbstractAlgebra.jl")
Nemo = PackageSpec(path="Nemo.jl")
Hecke = PackageSpec(path="Hecke.jl")
LoadFlint = PackageSpec(path="LoadFlint.jl")
Singular = PackageSpec(path="Singular.jl")
Polymake = PackageSpec(path="Polymake.jl")
HomalgProject = PackageSpec(path="HomalgProject.jl")
Oscar = PackageSpec(path="Oscar.jl")

PkgAdd(GAP)
PkgAdd(AbstractAlgebra)
PkgAdd(Nemo)
PkgAdd(Hecke)
PkgAdd(LoadFlint)
PkgAdd(Singular)
PkgAdd(Polymake)
PkgAdd(HomalgProject)
PkgAdd(Oscar)

Pkg.update()
