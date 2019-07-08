using Pkg
GAP = PackageSpec("GAP")
AbstractAlgebra = PackageSpec("AbstractAlgebra")
Nemo = PackageSpec("Nemo")
Hecke = PackageSpec("Hecke")
Singular = PackageSpec("Singular")
Polymake = PackageSpec("Polymake")
HomalgProject = PackageSpec("HomalgProject") # Does not work yet

Pkg.add(GAP)
Pkg.add(AbstractAlgebra)
Pkg.add(Nemo)
Pkg.add(Hecke)
Pkg.add(Singular)
Pkg.add(Polymake)
Pkg.add(HomalgProject)

Pkg.update()
