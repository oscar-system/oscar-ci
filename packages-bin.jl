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

GAP = PackageSpec("GAP")
AbstractAlgebra = PackageSpec("AbstractAlgebra")
Nemo = PackageSpec("Nemo")
Hecke = PackageSpec("Hecke")
LoadFlint = PackageSpec("LoadFlint")
Singular = PackageSpec("Singular")
Polymake = PackageSpec("Polymake")
HomalgProject = PackageSpec("HomalgProject")
Oscar = PackageSpec(path="Oscar.jl") # No binary package yet
Cxx = PackageSpec("Cxx")

PkgAdd(GAP)
PkgAdd(AbstractAlgebra)
PkgAdd(Nemo)
PkgAdd(Hecke)
PkgAdd(LoadFlint)
PkgAdd(Singular)
PkgAdd(Polymake)
PkgAdd(HomalgProject)
Pkg.add(Oscar)
Pkg.add(Cxx)

try
  Pkg.update()
catch
end
